//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract LarvaANT is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public HATCH_EPOCHS;
    uint256 public FOOD;
    uint256 public PORTION_FEE;
    uint256 public MAX_GENESIS_MINT;
    uint256 public LARVA_PRICE;
    uint256 public startDate;
    uint256 public duration;

    bool raceStarted;

    address public admin;
    uint256 public counter;
    uint256 public genesisCounter;

    mapping(uint256 => uint256) public idToSpawnTime;
    mapping(uint256 => uint256) public idToResource;
    mapping(uint256 => bool) public idToFed;
    mapping(uint256 => bool) public idToAtRisk;
    mapping(address => uint256[]) public playerToLarvae;
    mapping(address => uint256) public whitelist;

    function initialize(uint256 _duration) public initializer {
        __Ownable_init();
        __ERC721_init("Larva Ant", "LARVA");
        startDate = block.timestamp;
        raceStarted = true;
        duration = _duration;
        HATCH_EPOCHS = 3;
        FOOD = 5;
        PORTION_FEE = 80;
        MAX_GENESIS_MINT = 0;
        LARVA_PRICE = 0.0008 ether;
        counter = 1;
    }

    function getLarvae(address _user) public view returns (uint256[] memory) {
        return playerToLarvae[_user];
    }

    function getFeedable(address _user) public view returns (uint256 feedable) {
        uint256[] memory _playerToLarva = playerToLarvae[_user];
        feedable = 0;
        for (uint256 i = 0; i < _playerToLarva.length; i++) {
            if (idToFed[_playerToLarva[i]] == false) {
                feedable++;
            }
        }
    }

    function getHungryLarvae(address _user)
        public
        view
        returns (uint256[] memory _hungryLarvae)
    {
        uint256 feedable = getFeedable(_user);
        uint256[] memory _larvae = getLarvae(_user);
        _hungryLarvae = new uint256[](feedable);
        uint256 fed = 0;
        for (uint256 i = 0; i < _larvae.length; i++) {
            if (idToFed[_larvae[i]] == false) {
                _hungryLarvae[fed] = _larvae[i];
                fed++;
            }
        }
    }

    function getFed(address _user) public view returns (uint256 fed) {
        uint256[] memory larvaeList = playerToLarvae[_user];
        fed = 0;
        for (uint256 i = 0; i < larvaeList.length; i++) {
            if (idToFed[larvaeList[i]] == true) {
                fed++;
            }
        }
    }

    function getStolen(
        address _target,
        address _user,
        uint256 _larvaId
    ) public {
        _transfer(_target, _user, _larvaId);
        playerToLarvae[_user].push(_larvaId);
        for (uint256 i = 0; i < playerToLarvae[_target].length - 1; i++) {
            playerToLarvae[_target][i] = playerToLarvae[_target][i + 1];
        }
        playerToLarvae[_target].pop();
    }

    function getHatchersLength(address _user) public view returns (uint256) {
        uint256[] memory larvaeList = getLarvae(_user);
        uint256 _elapsedTime;
        uint256 hatchersLength;
        for (uint256 i = 0; i < larvaeList.length; i++) {
            _elapsedTime = block.timestamp - idToSpawnTime[larvaeList[i]];
            if (_elapsedTime >= HATCH_EPOCHS * duration) {
                hatchersLength++;
            }
        }
        return hatchersLength;
    }

    function setResourceCount(uint256 _index, uint256 _amount) public {
        idToResource[_index] = _amount;
    }

    function setProtected(uint256 _index) public {
        idToAtRisk[_index] = false;
    }

    function feedingLarva(
        address _user,
        uint256 _larvaAmount,
        uint256 _index
    ) public {
        uint256 _fed = 0;
        uint256[] memory _larvaeList = getLarvae(_user);
        for (uint256 i = 0; i < _larvaeList.length; i++) {
            if (idToFed[_index] == false && _larvaAmount >= _fed) {
                setResourceCount(_index, idToResource[_index] + FOOD);
                idToFed[_index] = true;
                _fed++;
            }
        }
    }

    function mint(address _user, uint256 _amount) public {
        uint256 _now = block.timestamp;
        for (uint256 i = 0; i < _amount; i++) {
            idToSpawnTime[counter] = _now;
            idToResource[counter] = 0;
            _mint(_user, counter);
            playerToLarvae[_user].push(counter);
            counter++;
        }
    }

    function burn(address _user, uint256 _id) public {
        require(playerToLarvae[_user].length > 0, "index out of bound");
        for (uint256 i = 0; i < playerToLarvae[_user].length - 1; i++) {
            playerToLarvae[_user][i] = playerToLarvae[_user][i + 1];
        }
        playerToLarvae[_user].pop();
        _burn(_id);
    }

    function drain() public {
        uint256 _amount = address(this).balance;
        (bool success, ) = admin.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) public {
        _setApprovalForAll(user, operator, approved);
    }
}
