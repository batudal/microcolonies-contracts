//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Incubator {
    function mateMalePrincess() public {
        bool _matingState = princess.mating();
        require(_matingState == false, "Mating in session.");
        uint256 _pairAmount = getPairs(msg.sender);
        uint256[] memory _maleList = male.getMales(msg.sender);
        uint256[] memory _princessList = princess.getPrincesses(msg.sender);
        uint256 speed = getSpeed(msg.sender);
        uint256[] memory males = new uint256[](_pairAmount);
        uint256[] memory princesses = new uint256[](_pairAmount);
        uint256 pairsAdded = 0;
        for (uint256 i; i < _pairAmount; i++) {
            princess.setMatingTime(_princessList[i]);
            princess.setMatingStatus(_princessList[i]);
            male.setMatingStatus(_maleList[i]);
            princesses[pairsAdded] = _princessList[i];
            males[pairsAdded] = _maleList[i];
            pairsAdded++;
        }
        princess.addMission(msg.sender, _maleList, _princessList, false, speed);
    }

    function getPairs(address _user) public view returns (uint256 _pair) {
        uint256 _maleCount = male.getMales(_user).length;
        uint256 _princessCount = princess.getPrincesses(_user).length;
        _pair = _maleCount >= _princessCount ? _princessCount : _maleCount;
    }

    function claimQueen(uint256 _missionIndex) public {
        uint256[] memory _matedMales = male.getMatedMales(msg.sender);
        uint256[] memory _matedPrincesses = princess.getMatedPrincesses(
            msg.sender
        );
        uint256 _amount = princess
            .getMissionIds(msg.sender, _missionIndex)
            .length;

        uint256 _now = block.timestamp;
        nonce++;
        uint256 prob = uint256(keccak256(abi.encodePacked(msg.sender, nonce))) %
            100;
        uint256 seasonBonus;
        for (uint256 i = 0; i < 3; i++) {
            if (
                _now >= matingDates[i] &&
                _now <= (matingDates[i] + (tournamentDuration / 16))
            ) {
                seasonBonus = 60;
            } else {
                seasonBonus = 0;
            }
        }
        uint256 prob_;
        uint256 variant;
        for (uint256 i; i < _amount; i++) {
            uint256 missionEnd = princess.getMissionEnd(
                msg.sender,
                _missionIndex
            );
            if (missionEnd < block.timestamp) {
                variant = uint256(keccak256(abi.encodePacked(i, msg.sender)));
                prob_ = (variant + prob) % 100;
                if (prob_ < 20 + seasonBonus) {
                    male.burn(msg.sender, _matedMales[i]);
                    increaseAvailableSpace(msg.sender);
                    princess.burn(msg.sender, _matedPrincesses[i]);
                    increaseAvailableSpace(msg.sender);
                    queen.mint(msg.sender);
                } else {
                    male.burn(msg.sender, _matedMales[i]);
                    increaseAvailableSpace(msg.sender);
                }
            }
        }
        princess.finalizeMission(msg.sender, _missionIndex);
    }

    function getSeasonBonus() public view returns (uint256) {
        uint256 _now = block.timestamp;
        for (uint256 i = 0; i < 3; i++) {
            if (
                _now >= matingDates[i] &&
                _now <= (matingDates[i] + (tournamentDuration / 16))
            ) {
                return 60;
            }
        }
        return 0;
    }

    function getNextSeason() public view returns (uint256) {
        uint256 _now = block.timestamp;
        for (uint256 i = 0; i < 3; i++) {
            if (_now < matingDates[i]) {
                return matingDates[i] - _now;
            }
        }
        return 0;
    }

    function feedLarva(uint256 _larvaAmount) public {
        uint256 feedable = larva.getFeedable(msg.sender);
        require(feedable >= _larvaAmount, "You don't have enough hungry larva");
        uint256[] memory hungryLarvae = larva.getHungryLarvae(msg.sender);

        uint256 _amount = larva.FOOD() * larva.PORTION_FEE() * 1e18;
        //parası var mı check ekle

        for (uint256 i = 0; i < _larvaAmount; i++) {
            funghi.transferFrom(msg.sender, address(this), _amount);
            larva.feedingLarva(msg.sender, _larvaAmount, hungryLarvae[i]);
            feromon.mint(msg.sender, 1);
        }
    }

    function hatch(uint256 _amount) public {
        if (firstMint[msg.sender] == false) {
            playerToCapacity[msg.sender] = 10;
            playerToAvailableSpace[msg.sender] = 10;
        }
        uint256 _maxPossible = playerToAvailableSpace[msg.sender];
        require(_amount <= _maxPossible, "NO");

        uint256 prob = uint256(keccak256(abi.encodePacked(msg.sender, nonce))) %
            100;
        nonce++;
        uint256 prob_;
        uint256 variant;
        uint256[] memory larvaeList;

        for (uint256 j = 0; j < _amount; j++) {
            larvaeList = larva.getLarvae(msg.sender);

            variant = uint256(keccak256(abi.encodePacked(j, msg.sender)));
            prob_ =
                (variant + prob) %
                (100 - larva.idToResource(larvaeList[0]) * 10);
            emit logProb(j, prob_);
            if (firstMint[msg.sender] == false) {
                queen.mint(msg.sender);
                uint256[] memory _queenList = queen.getQueens(msg.sender);
                queen.setHousing(_queenList[_queenList.length - 1], true);
                decreaseAvailableSpace(msg.sender);
                firstMint[msg.sender] = true;
            } else if (prob_ < 3) {
                princess.mint(msg.sender);
                uint256[] memory _princessList = princess.getPrincesses(
                    msg.sender
                );
                princess.setHousing(
                    _princessList[_princessList.length - 1],
                    true
                );
                decreaseAvailableSpace(msg.sender);
            } else if (prob_ >= 3 && prob_ < 18) {
                male.mint(msg.sender);
                uint256[] memory _maleList = male.getMales(msg.sender);
                male.setHousing(_maleList[_maleList.length - 1], true);
                decreaseAvailableSpace(msg.sender);
            } else if (prob_ >= 18 && prob_ < 33) {
                soldier.mint(msg.sender);
                uint256[] memory _soldierList = soldier.getSoldiers(msg.sender);
                soldier.setHousing(_soldierList[_soldierList.length - 1], true);
                decreaseAvailableSpace(msg.sender);
            } else if (prob_ >= 33 && prob_ < 100) {
                worker.mint(msg.sender);
                uint256[] memory _workerList = worker.getWorkers(msg.sender);
                worker.setHousing(_workerList[_workerList.length - 1], true);
                decreaseAvailableSpace(msg.sender);
            }
            larva.burn(msg.sender, larvaeList[0]);
            feromon.mint(msg.sender, 1);
        }
    }

    function layEggs(uint256 _index) public {
        uint256 _totalEggs = queen.eggsFormula(_index);
        uint256 deservedEggs = _totalEggs - queen.idToEggs(_index);
        if (deservedEggs > 0) {
            queen.setEggCount(_index, deservedEggs);
            larva.mint(msg.sender, deservedEggs);
            feromon.mint(msg.sender, deservedEggs);
        }
    }

    function feedQueen(uint256 _index) public {
        layEggs(_index);
        uint256 epochsElapsed = queen.getEpoch(_index);
        uint256 _amount = epochsElapsed * queen.PORTION_FEE() * 1e18;
        queen.feedQueen(_index);
        funghi.transferFrom(msg.sender, address(this), _amount);
        feromon.mint(msg.sender, epochsElapsed);
        queen.resetEggCount(_index);
    }

    function queenLevelUp(uint256 _index) public {
        if (queen.idToLevel(_index) == 1) {
            feromon.transferFrom(
                msg.sender,
                address(this),
                feromon.QUEEN_UPGRADE_FEE()
            );
        } else if (queen.idToLevel(_index) == 2) {
            feromon.transferFrom(
                msg.sender,
                address(this),
                feromon.QUEEN_UPGRADE_FEE() * 3
            );
        }
        layEggs(_index);
        queen.feedQueen(_index);
        queen.resetEggCount(_index);
        queen.queenLevelup(_index);
    }
}
