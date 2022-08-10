//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Interfaces/IWorkerANT.sol";
import "./Interfaces/ISoldierANT.sol";
import "./Interfaces/IQueenANT.sol";
import "./Interfaces/ILarvaANT.sol";
import "./Interfaces/IMaleANT.sol";
import "./Interfaces/IPrincessANT.sol";
import "./Interfaces/IFunghiToken.sol";
import "./Interfaces/IFeromonToken.sol";
import "./Interfaces/ILollipop.sol";

contract ANT {
    IWorkerANT public worker;
    ISoldierANT public soldier;
    IQueenANT public queen;
    ILarvaANT public larva;
    IMaleANT public male;
    IPrincessANT public princess;
    IFunghiToken public funghi;
    IFeromonToken public feromon;
    ILollipop public lollipop;
    address[] public participants;
    uint256 public tournamentDuration;

    struct Mission {
        uint256 start;
        uint256 end;
        uint256[] ids;
        uint256 missionType; // 0-stake, 1-build
        bool finalized;
    }

    mapping(address => bool) public firstMint;
    mapping(address => uint256) public playerToCapacity;
    mapping(address => uint256) public playerToAvailableSpace;
    mapping(address => uint256) public playerToLollipop;
    mapping(address => address) public playerToTarget;
    uint256 nonce;
    bool initialized;
    uint256 startDate;
    uint256[] public matingDates;

    event logProb(uint256 round, uint256 prob_);

    function initialize(
        address _queenAddress,
        address _larvaAddress,
        address _workerAddress,
        address _soldierAddress,
        address _maleAddress,
        address _princessAddress,
        address _lollipopAddress,
        address _funghiAddress,
        address _feromonAddress,
        uint256 _tournamentDuration,
        uint256 _startDate
    ) external {
        require(!initialized, "Already initialized.");
        queen = IQueenANT(_queenAddress);
        larva = ILarvaANT(_larvaAddress);
        worker = IWorkerANT(_workerAddress);
        soldier = ISoldierANT(_soldierAddress);
        male = IMaleANT(_maleAddress);
        princess = IPrincessANT(_princessAddress);
        lollipop = ILollipop(_lollipopAddress);
        funghi = IFunghiToken(_funghiAddress);
        feromon = IFeromonToken(_feromonAddress);
        initialized = true;
        nonce = 324;
        startDate = _startDate;
        tournamentDuration = _tournamentDuration;
        matingDates = [
            (startDate + (_tournamentDuration * 1) / 4),
            (startDate + (_tournamentDuration * 2) / 4),
            (startDate + (_tournamentDuration * 3) / 4)
        ];
    }

    function addParticipants(address[] memory _participants) public {
        participants = _participants;
    }

    function getSpeed(address _user) public view returns (uint256 speed) {
        uint256 _id = lollipop.playerToLollipopId(_user);
        uint256 _now = block.timestamp;
        uint256 _time = lollipop.idToTimestamp(_id);
        uint256 _duration = lollipop.duration();
        if (_time + _duration > _now) {
            speed = 2;
        } else {
            speed = 1;
        }
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

    function getHomelessAntCount(address _user)
        public
        view
        returns (uint256 _homelessAntCount)
    {
        uint256 _homelessWorkerCount = worker.getHomelessCount(_user);
        uint256 _homelessSoldierCount = soldier.getHomelessCount(_user);
        uint256 _homelessMaleCount = male.getHomelessCount(_user);
        uint256 _homelessPrincessCount = princess.getHomelessCount(_user);
        uint256 _homelessQueenCount = queen.getHomelessCount(_user);
        _homelessAntCount =
            _homelessWorkerCount +
            _homelessSoldierCount +
            _homelessMaleCount +
            _homelessPrincessCount +
            _homelessQueenCount;
        return _homelessAntCount;
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

    function expandNest(uint256 _amount) public {
        uint256[] memory availableWorkerList = worker.getAvailableWorkers(
            msg.sender
        );
        require(_amount <= availableWorkerList.length);
        uint256[] memory workerList = new uint256[](_amount);
        uint256 _workerOnMission = 0;
        for (uint256 j = 0; j < _amount; j++) {
            worker.setBuildMission(availableWorkerList[j], true);
            worker.setBuildDate(availableWorkerList[j], block.timestamp);
            worker.transferFrom(
                msg.sender,
                address(this),
                availableWorkerList[j]
            );
            workerList[_workerOnMission] = availableWorkerList[j];
            _workerOnMission++;
            feromon.mint(msg.sender, 1);
        }
        uint256 speed = getSpeed(msg.sender);
        worker.addMission(msg.sender, workerList, 1, false, speed);
    }

    function increaseCapacity(address _user) public {
        playerToAvailableSpace[_user] += 5;
        playerToCapacity[_user] += 5;
    }

    function decreaseAvailableSpace(address _user) public {
        playerToAvailableSpace[_user] -= 1;
    }

    function increaseAvailableSpace(address _user) public {
        playerToAvailableSpace[_user] += 1;
    }

    function claimAndIncreaseSpace(uint256 _missionIndex) public {
        uint256[] memory builders = worker.getMissionIds(
            msg.sender,
            _missionIndex
        );
        uint256 missionEnd = worker.getMissionEnd(msg.sender, _missionIndex);

        for (uint256 i; i < builders.length; i++) {
            if (missionEnd <= block.timestamp) {
                increaseCapacity(msg.sender);
                worker.setBuildMission(builders[i], false);
                worker.transferFrom(address(this), msg.sender, builders[i]);
                worker.reduceHP(msg.sender, builders[i]);
            }
        }
        worker.finalizeMission(msg.sender, _missionIndex);
    }

    function convertFromWorkerToSoldier(uint256 _amount) public {
        uint256[] memory workers = worker.getAvailableWorkers(msg.sender);
        require(_amount <= workers.length, "Not enough workers.");
        require(
            _amount * feromon.CONVERSION_FEE() <= feromon.balanceOf(msg.sender),
            "Not enough feromons."
        );
        for (uint256 i = 0; i < _amount; i++) {
            feromon.transferFrom(
                msg.sender,
                address(this),
                feromon.CONVERSION_FEE()
            );
            worker.burn(msg.sender, workers[i]);
            soldier.mint(msg.sender);
        }
    }

    function setPlayerToTarget(address _user, address _target) public {
        playerToTarget[_user] = _target;
    }

    function findTarget(uint256 _amount) public {
        uint256[] memory availableSoldierList = soldier.getAvailableSoldiers(
            msg.sender
        );
        require(_amount <= availableSoldierList.length, "Not enough soldiers.");
        uint256[] memory soldierList = new uint256[](_amount);
        uint256 _soldierOnMission = 0;
        for (uint256 i; i < _amount; i++) {
            soldier.setRaidMission(availableSoldierList[i], true);
            soldier.setRaidDate(availableSoldierList[i], block.timestamp);
            soldier.transferFrom(
                msg.sender,
                address(this),
                availableSoldierList[i]
            );
            soldierList[_soldierOnMission] = availableSoldierList[i];
            _soldierOnMission++;
            feromon.mint(msg.sender, 1);
            soldier.infectionSpread(msg.sender);
        }
        uint256 speed = getSpeed(msg.sender);
        soldier.addMission(msg.sender, soldierList, false, speed);
    }

    function otherParticipants(address _user)
        public
        view
        returns (address[] memory _participants)
    {
        uint256 participantAdded = 0;
        _participants = new address[](participants.length - 1);
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] != _user) {
                _participants[participantAdded] = participants[i];
                participantAdded++;
            }
        }
        return _participants;
    }

    function revealTarget(uint256 _missionId)
        public
        view
        returns (address _target)
    {
        uint256 _end = soldier.getMissionEnd(msg.sender, _missionId);
        require(_end < block.timestamp, "Mission is not over yet.");
        address[] memory remainingParticipants = otherParticipants(msg.sender);
        uint256 prob = uint256(keccak256(abi.encodePacked(msg.sender, nonce))) %
            remainingParticipants.length;
        _target = remainingParticipants[prob];
        return _target;
    }

    function retreatSoldiers(uint256 _missionId) public {
        uint256[] memory missionParticipants = soldier
            .getMissionParticipantList(msg.sender, _missionId);
        uint256 _end = soldier.getMissionEnd(msg.sender, _missionId);
        for (uint256 i; i < missionParticipants.length; i++) {
            if (_end < block.timestamp) {
                soldier.setRaidMission(missionParticipants[i], false);
                soldier.transferFrom(
                    address(this),
                    msg.sender,
                    missionParticipants[i]
                );
            }
        }
        soldier.finalizeMission(msg.sender, _missionId);
    }

    function claimStolenLarvae(uint256 _missionId) public {
        uint256[] memory missionParticipants = soldier
            .getMissionParticipantList(msg.sender, _missionId);
        uint256 targetSoldierCount = soldier
            .getAvailableSoldiers(revealTarget(_missionId))
            .length;
        uint256[] memory targetLarvae = larva.getLarvae(
            revealTarget(_missionId)
        );
        uint256 attackerSoldierCount = soldier.getMissionPartipants(
            msg.sender,
            _missionId
        );
        (uint256 prize, uint256 bonus) = soldier.battle(
            attackerSoldierCount,
            targetSoldierCount,
            targetLarvae.length
        );

        for (uint256 i = 0; i < missionParticipants.length; i++) {
            if (
                soldier.getMissionEnd(msg.sender, _missionId) < block.timestamp
            ) {
                soldier.increaseDamage(missionParticipants[i]);
                soldier.setRaidMission(missionParticipants[i], false);
                soldier.transferFrom(
                    address(this),
                    msg.sender,
                    missionParticipants[i]
                );
            }
        }
        soldier.finalizeMission(msg.sender, _missionId);

        if (prize == 0 && bonus == 0) {
            return ();
        }
        // prize = prize >= targetLarvae.length ? targetLarvae.length : prize;
        uint256[] memory larvaToBeBurnt = new uint256[](prize + bonus);
        uint256 larvaeAdded = 0;
        for (uint256 i = 0; i < prize + bonus; i++) {
            larvaToBeBurnt[larvaeAdded] = targetLarvae[i];
            larvaeAdded++;
        }
        for (uint256 i = 0; i < prize + bonus; i++) {
            larva.getStolen(
                revealTarget(_missionId),
                msg.sender,
                larvaToBeBurnt[i]
            );
        }
    }

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

    function getPopulation() public view returns (uint256 count) {
        count += worker.getWorkers(msg.sender).length;
        count += soldier.getSoldiers(msg.sender).length;
        count += queen.getQueens(msg.sender).length;
        count += male.getMales(msg.sender).length;
        count += princess.getPrincesses(msg.sender).length;
    }
}
