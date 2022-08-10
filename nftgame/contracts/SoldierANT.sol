//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Interfaces/ILollipop.sol";
import "./Interfaces/IFeromonToken.sol";
import "./Interfaces/IFunghiToken.sol";
import "hardhat/console.sol";

contract SoldierANT is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public counter;
    uint256 public RAID_EPOCHS;
    uint256 public HEAL_EPOCHS;
    uint256 public HEALING_FEE;
    uint256 public MAX_DAMAGE_COUNT;
    uint256 private nonce;
    uint256 public duration;
    address public lollipop;
    address public feromon;
    address public funghi;

    function initialize(
        uint256 _epochDuration,
        address _lollipop,
        address _feromon,
        address _funghi
    ) public initializer {
        __Ownable_init();
        __ERC721_init("Soldier Ant", "SOLDIER");
        duration = _epochDuration;
        RAID_EPOCHS = 3;
        HEAL_EPOCHS = 3;
        HEALING_FEE = 80;
        MAX_DAMAGE_COUNT = 3;
        counter = 1;
        nonce = 42;
        lollipop = _lollipop;
        feromon = _feromon;
        funghi = _funghi;
    }

    mapping(uint256 => uint256) public idToDamageCount;
    mapping(uint256 => uint256) public idToFinalDamageDate;
    mapping(uint256 => uint256) public idToRaidDate;
    mapping(uint256 => bool) public idToOnRaidMission;
    mapping(uint256 => bool) public idToHousing;
    mapping(uint256 => bool) public idToPassive;
    mapping(address => uint256[]) public playerToSoldiers;

    struct Mission {
        uint256 start;
        uint256 end;
        uint256[] ids;
        bool finalized;
    }
    mapping(address => Mission[]) public userMissions;

    function getMissions(address _user) public view returns (Mission[] memory) {
        return userMissions[_user];
    }

    function addMission(
        address _user,
        uint256[] memory _ids,
        bool _finalized,
        uint256 speed
    ) public {
        userMissions[_user].push(
            Mission({
                start: block.timestamp,
                end: block.timestamp + (RAID_EPOCHS * duration) / speed,
                ids: _ids,
                finalized: _finalized
            })
        );
    }

    function finalizeMission(address _user, uint256 _index) public {
        userMissions[_user][_index].finalized = true;
    }

    function getMissionEnd(address _user, uint256 _index)
        public
        view
        returns (uint256 _end)
    {
        _end = userMissions[_user][_index].end;
        return _end;
    }

    function getMissionPartipants(address _user, uint256 _index)
        public
        view
        returns (uint256 missionParticipants)
    {
        missionParticipants = userMissions[_user][_index].ids.length;
    }

    function getMissionParticipantList(address _user, uint256 _index)
        public
        view
        returns (uint256[] memory missionParticipants)
    {
        missionParticipants = userMissions[_user][_index].ids;
    }

    function getAvailableSoldiers(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256 soldierCounter;
        uint256[] memory _soldierList = playerToSoldiers[_user];
        uint256 _soldierOnRaidCount;
        uint256 _stakedSoldierCount;
        uint256 _zombieSoldierCount;
        for (uint256 i = 0; i < _soldierList.length; i++) {
            if (idToOnRaidMission[_soldierList[i]]) {
                _soldierOnRaidCount++;
            } else if (idToPassive[_soldierList[i]]) {
                _zombieSoldierCount++;
            }
        }
        uint256[] memory availableSoldierList = new uint256[](
            _soldierList.length -
                _soldierOnRaidCount -
                _stakedSoldierCount -
                _zombieSoldierCount
        );
        for (uint256 i; i < _soldierList.length; i++) {
            if (
                !idToOnRaidMission[_soldierList[i]] &&
                !idToPassive[_soldierList[i]]
            ) {
                availableSoldierList[soldierCounter] = _soldierList[i];
                soldierCounter++;
            }
        }
        return availableSoldierList;
    }

    function getZombieSoldiers(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _soldierList = playerToSoldiers[_user];
        uint256 passiveSoldierCount;
        for (uint256 i = 0; i < _soldierList.length; i++) {
            if (idToPassive[_soldierList[i]]) {
                passiveSoldierCount++;
            }
        }
        uint256[] memory zombieSoldierList = new uint256[](passiveSoldierCount);
        uint256 zombieSoldierCount;
        for (uint256 i; i < _soldierList.length; i++) {
            if (idToPassive[_soldierList[i]] == true) {
                zombieSoldierList[zombieSoldierCount] = _soldierList[i];
                zombieSoldierCount++;
            }
        }
        return zombieSoldierList;
    }

    function harvestZombie(uint256 _amount) public {
        uint256[] memory zombies = getZombieSoldiers(msg.sender);
        require(zombies.length >= _amount);
        for (uint256 i; i < _amount; i++) {
            burn(msg.sender, zombies[i]);
            IFunghiToken(funghi).burst(msg.sender);
        }
    }

    function healSoldier(uint256 _soldierAmount) public {
        uint256[] memory _soldierList = getSoldiers(msg.sender);
        uint256 _healedSoldiers;
        uint256[] memory _infectedSoldierList = getInfectedSoldiers(msg.sender);
        require(
            _soldierAmount <= _infectedSoldierList.length,
            "Not enough damaged soldiers."
        );

        for (uint256 i = 0; i < _soldierList.length; i++) {
            uint256 _soldierDamage = idToDamageCount[_soldierList[i]];
            if (_soldierDamage == 3 && _healedSoldiers < _soldierAmount) {
                IFunghiToken(funghi).burn(msg.sender, HEALING_FEE * 1e18);
                reduceDamage(_soldierList[i], 3);
                _healedSoldiers++;
            }
        }
        if (_healedSoldiers < _soldierAmount) {
            for (uint256 i = 0; i < _soldierList.length; i++) {
                uint256 _soldierDamage = idToDamageCount[_soldierList[i]];
                if (_soldierDamage == 2) {
                    IFunghiToken(funghi).burn(msg.sender, HEALING_FEE * 1e18);
                    reduceDamage(_soldierList[i], 2);
                    _healedSoldiers++;
                }
            }
        }
        if (_healedSoldiers < _soldierAmount) {
            for (uint256 i = 0; i < _soldierList.length; i++) {
                uint256 _soldierDamage = idToDamageCount[_soldierList[i]];
                if (_soldierDamage == 1) {
                    IFunghiToken(funghi).burn(msg.sender, HEALING_FEE * 1e18);
                    reduceDamage(_soldierList[i], 1);
                    _healedSoldiers++;
                }
            }
        }
        IFeromonToken(feromon).mint(msg.sender, _soldierAmount);
    }

    function getInfectionRate(address _user)
        public
        view
        returns (uint256 infectionRate)
    {
        uint256 _totalDamageCount = 0;
        uint256[] memory _soldierList = playerToSoldiers[_user];
        for (uint256 i = 0; i < _soldierList.length; i++) {
            if (
                idToDamageCount[_soldierList[i]] > 0 &&
                !idToPassive[_soldierList[i]]
            ) {
                _totalDamageCount += idToDamageCount[_soldierList[i]];
            }
        }
        uint256 _activeSoldierCount = 0;
        for (uint256 i = 0; i < _soldierList.length; i++) {
            if (!idToPassive[_soldierList[i]]) {
                _activeSoldierCount++;
            }
        }
        uint256 _maxPossibleDamage = _activeSoldierCount * MAX_DAMAGE_COUNT;
        infectionRate = (_totalDamageCount * 100) / _maxPossibleDamage;
        return infectionRate;
    }

    function battle(
        uint256 attackerSoldierCount,
        uint256 targetSoldierCount,
        uint256 targetLarvaeCount
    ) public returns (uint256 prize, uint256 bonus) {
        uint256 rollCount = attackerSoldierCount > targetLarvaeCount
            ? targetLarvaeCount
            : attackerSoldierCount;
        uint256[] memory targetRolls = new uint256[](rollCount);
        uint256[] memory attackerRolls = new uint256[](rollCount);
        quick(targetRolls);
        quick(attackerRolls);
        uint256 attackerWins = 0;
        uint256 defenderWins = 0;
        for (uint256 i = 0; i < rollCount; i++) {
            if (attackerRolls[i] > targetRolls[i]) {
                attackerWins++;
            } else {
                defenderWins++;
            }
        }
        if (attackerWins > defenderWins) {
            prize = attackerWins - defenderWins;
        } else {
            prize = 0;
        }
        if (attackerSoldierCount > targetSoldierCount) {
            uint256 remainingAttacks = attackerSoldierCount -
                targetSoldierCount;
            for (uint256 i = 0; i < remainingAttacks; i++) {
                uint256 chance = uint256(
                    keccak256(abi.encodePacked(msg.sender, nonce))
                ) % 100;
                nonce++;
                if (chance < 80) {
                    bonus++;
                }
            }
        }
    }

    function quick(uint256[] memory data) internal pure {
        if (data.length > 1) {
            quickPart(data, 0, data.length - 1);
        }
    }

    function quickPart(
        uint256[] memory data,
        uint256 low,
        uint256 high
    ) internal pure {
        if (low < high) {
            uint256 pivotVal = data[(low + high) / 2];

            uint256 low1 = low;
            uint256 high1 = high;
            for (;;) {
                while (data[low1] < pivotVal) low1++;
                while (data[high1] > pivotVal) high1--;
                if (low1 >= high1) break;
                (data[low1], data[high1]) = (data[high1], data[low1]);
                low1++;
                high1--;
            }
            if (low < high1) quickPart(data, low, high1);
            high1++;
            if (high1 < high) quickPart(data, high1, high);
        }
    }

    function getInfectedSoldiers(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _soldierList = playerToSoldiers[_user];
        uint256 soldierWithDamageCount = 0;
        for (uint256 i = 0; i < _soldierList.length; i++) {
            if (
                idToDamageCount[_soldierList[i]] > 0 &&
                !idToPassive[_soldierList[i]]
            ) {
                soldierWithDamageCount++;
            }
        }
        uint256[] memory infectedSoldierList = new uint256[](
            soldierWithDamageCount
        );

        uint256 infectedSoldierCount = 0;
        for (uint256 i; i < _soldierList.length; i++) {
            if (
                idToDamageCount[_soldierList[i]] > 0 &&
                !idToPassive[_soldierList[i]]
            ) {
                infectedSoldierList[infectedSoldierCount] = _soldierList[i];
                infectedSoldierCount++;
            }
        }
        return infectedSoldierList;
    }

    function getSoldiers(address _user) public view returns (uint256[] memory) {
        return playerToSoldiers[_user];
    }

    function setHousing(uint256 _index, bool _status) public {
        idToHousing[_index] = _status;
    }

    function setRaidMission(uint256 _index, bool _status) public {
        idToOnRaidMission[_index] = _status;
    }

    function setRaidDate(uint256 _index, uint256 _buildDate) public {
        idToRaidDate[_index] = _buildDate;
    }

    function getHomelessCount(address _user) public view returns (uint256) {
        uint256 _homeless = 0;
        uint256[] memory _soldierList = playerToSoldiers[_user];
        for (uint256 i; i < _soldierList.length; i++) {
            if (!idToHousing[_soldierList[i]]) {
                _homeless += 1;
            }
        }
        return _homeless;
    }

    function getUnHousedSoldiers(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _soldierList = getSoldiers(_user);
        uint256 _homelessCount = getHomelessCount(_user);
        uint256 _soldiersHoused = 0;
        uint256[] memory _unhousedSoldierList = new uint256[](_homelessCount);
        for (uint256 i = 0; i < _soldierList.length; i++) {
            if (!idToHousing[_soldierList[i]]) {
                _unhousedSoldierList[_soldiersHoused] = _soldierList[i];
                _soldiersHoused++;
            }
        }
        return _unhousedSoldierList;
    }

    function increaseDamage(uint256 _index) public {
        idToDamageCount[_index] += 1;
        uint256 _timeElapsed = block.timestamp - idToFinalDamageDate[_index];

        if (
            idToDamageCount[_index] == MAX_DAMAGE_COUNT &&
            _timeElapsed > HEAL_EPOCHS * duration
        ) {
            idToPassive[_index] = true;
        }
    }

    function getClaimableLarvaCount(address _user)
        public
        view
        returns (uint256 _count)
    {
        uint256[] memory _soldierList = playerToSoldiers[_user];
        uint256 _claimableLarvaCount;
        for (uint256 i = 0; i < _soldierList.length; i++) {
            if (
                idToOnRaidMission[_soldierList[i]] &&
                RAID_EPOCHS * duration <=
                block.timestamp - idToRaidDate[_soldierList[i]]
            ) {
                _claimableLarvaCount++;
            }
        }
        return _claimableLarvaCount;
    }

    function infectionSpread(address _user) public {
        uint256[] memory _soldierList = playerToSoldiers[_user];
        uint256[] memory _infectedList = getInfectedSoldiers(_user);
        for (uint256 i = 0; i < _soldierList.length; i++) {
            if (_infectedList.length > 0) {
                uint256 chance = uint256(
                    keccak256(abi.encodePacked(msg.sender, nonce))
                ) % 100;
                if (
                    chance < 1 &&
                    idToPassive[_soldierList[i]] == false &&
                    idToDamageCount[_soldierList[i]] < MAX_DAMAGE_COUNT
                ) {
                    increaseDamage(_soldierList[i]);
                }
            }
        }
    }

    function reduceDamage(uint256 _index, uint256 _damageReduced) public {
        require(idToDamageCount[_index] >= _damageReduced);
        uint256 _damageCount = idToDamageCount[_index];
        for (uint256 i = 0; i < _damageReduced; i++) {
            _damageCount -= 1;
        }
        idToDamageCount[_index] = _damageCount;
    }

    function burn(address _user, uint256 _index) public {
        require(playerToSoldiers[_user].length > 0, "index out of bound");
        uint256 _listIndex;
        for (uint256 i = 0; i < playerToSoldiers[_user].length; i++) {
            if (playerToSoldiers[_user][i] == _index) {
                _listIndex = i;
            }
        }
        playerToSoldiers[_user][_listIndex] = playerToSoldiers[_user][
            playerToSoldiers[_user].length - 1
        ];
        playerToSoldiers[_user].pop();
        _burn(_index);
    }

    function mint(address _user) public {
        idToDamageCount[counter] = 0;
        idToOnRaidMission[counter] = false;
        idToHousing[counter] = false;
        idToPassive[counter] = false;

        _mint(_user, counter);
        playerToSoldiers[_user].push(counter);
        counter++;
    }

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) public {
        _setApprovalForAll(user, operator, approved);
    }
}
