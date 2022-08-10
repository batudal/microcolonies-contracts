//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract QueenANT is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public counter;
    uint256 public PORTION_FEE;
    uint256 public LEVEL_UP_FEE;
    uint256 public duration;

    function initialize(uint256 _epochDuration) public initializer {
        __Ownable_init();
        __ERC721_init("Queen Ant", "QUEEN");
        duration = _epochDuration;
        PORTION_FEE = 240;
        LEVEL_UP_FEE = 100;
        counter = 1;
        levelToFertility[1] = 5;
        levelToFertility[2] = 9;
        levelToFertility[3] = 12;
    }

    mapping(uint256 => uint256) public idToTimestamp;
    mapping(uint256 => uint256) public idToLevel;
    mapping(uint256 => uint256) public idToEggs;
    mapping(uint256 => bool) public idToHousing;
    mapping(address => uint256[]) public playerToQueens;
    mapping(uint256 => uint256) public levelToFertility;

    function getEpoch(uint256 _index)
        public
        view
        returns (uint256 epochsElapsed)
    {
        uint256 timeElapsed = block.timestamp - idToTimestamp[_index];
        epochsElapsed = (timeElapsed / duration);
        uint256 _level = idToLevel[_index];
        uint256 _levelToFert = levelToFertility[_level];
        if (epochsElapsed > _levelToFert) {
            epochsElapsed = _levelToFert;
        }
    }

    function getQueens(address _user) public view returns (uint256[] memory) {
        return playerToQueens[_user];
    }

    function setEggCount(uint256 _index, uint256 _eggCount) public {
        idToEggs[_index] += _eggCount;
    }

    function feedQueen(uint256 _index) public {
        setTimestamp(_index, block.timestamp);
        resetEggCount(_index);
    }

    function resetEggCount(uint256 _index) public {
        idToEggs[_index] = 0;
    }

    function setTimestamp(uint256 _index, uint256 _timestamp) public {
        idToTimestamp[_index] = _timestamp;
    }

    function setHousing(uint256 _index, bool _status) public {
        idToHousing[_index] = _status;
    }

    function getHomelessCount(address _user) public view returns (uint256) {
        uint256 _homeless = 0;
        uint256[] memory _queenList = playerToQueens[_user];
        for (uint256 i; i < _queenList.length; i++) {
            if (!idToHousing[_queenList[i]]) {
                _homeless += 1;
            }
        }
        return _homeless;
    }

    function queenLevelup(uint256 _index) public {
        uint256 _level = idToLevel[_index];
        require(_level < 3);
        idToLevel[_index] += 1;
    }

    function getUnHousedQueens(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _queenList = getQueens(_user);
        uint256 _homelessCount = getHomelessCount(_user);
        uint256 _queensHoused = 0;
        uint256[] memory _unhousedQueenList = new uint256[](_homelessCount);
        for (uint256 i = 0; i < _queenList.length; i++) {
            if (!idToHousing[_queenList[i]]) {
                _unhousedQueenList[_queensHoused] = _queenList[i];
                _queensHoused++;
            }
        }
        return _unhousedQueenList;
    }

    function eggsFormula(uint256 _index)
        public
        view
        returns (uint256 _totalEggs)
    {
        uint256 _level = idToLevel[_index];
        uint256 _startingFert = levelToFertility[_level];
        uint256 _epochElapsed = getEpoch(_index);
        for (uint256 i = 0; i < _epochElapsed; i++) {
            _totalEggs += _startingFert;
            _startingFert -= 1;
        }
    }

    function mint(address _user) public {
        idToEggs[counter] = 0;
        idToLevel[counter] = 1;
        idToHousing[counter] = false;
        idToTimestamp[counter] = block.timestamp;
        _mint(_user, counter);
        playerToQueens[_user].push(counter);
        counter++;
    }

    function getEnergy(uint256 _index)
        public
        view
        returns (uint256 _percentage)
    {
        uint256 _capacity = duration * levelToFertility[idToLevel[_index]];
        uint256 _diff = block.timestamp - idToTimestamp[_index];
        if (_diff > _capacity) {
            _percentage = 0;
        } else {
            _percentage = ((_capacity - _diff) * 100) / _capacity;
        }
    }

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) public {
        _setApprovalForAll(user, operator, approved);
    }
}
