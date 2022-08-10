//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MaleANT is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public counter;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("Drone Ant", "DRONE");
        counter = 1;
    }

    mapping(uint256 => uint256) public idToMateTime;
    mapping(address => uint256[]) public playerToMales;
    mapping(uint256 => bool) public idToVirginity;
    mapping(uint256 => bool) public idToHousing;

    function setMatingTime(uint256 _maleIndex) public {
        idToMateTime[_maleIndex] = block.timestamp;
    }

    function setMatingStatus(uint256 _index) public {
        idToVirginity[_index] = false;
    }

    function getMales(address _user) public view returns (uint256[] memory) {
        return playerToMales[_user];
    }

    function setHousing(uint256 _index, bool _status) public {
        idToHousing[_index] = _status;
    }

    function getHomelessCount(address _user) public view returns (uint256) {
        uint256 _homeless = 0;
        uint256[] memory _maleList = playerToMales[_user];
        for (uint256 i; i < _maleList.length; i++) {
            if (!idToHousing[_maleList[i]]) {
                _homeless += 1;
            }
        }
        return _homeless;
    }

    function getUnHousedMales(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _maleList = getMales(_user);
        uint256 _homelessCount = getHomelessCount(_user);
        uint256 _malesHoused = 0;
        uint256[] memory _unhousedMalesList = new uint256[](_homelessCount);
        for (uint256 i = 0; i < _maleList.length; i++) {
            if (!idToHousing[_maleList[i]]) {
                _unhousedMalesList[_malesHoused] = _maleList[i];
                _malesHoused++;
            }
        }
        return _unhousedMalesList;
    }

    function getMatedMales(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _maleList = playerToMales[_user];
        uint256 matedMaleLength = 0;
        for (uint256 i; i < _maleList.length; i++) {
            if (idToVirginity[_maleList[i]] == false) {
                matedMaleLength++;
            }
        }
        uint256[] memory matedMaleList = new uint256[](matedMaleLength);
        uint256 matedMaleCount;
        for (uint256 i; i < _maleList.length; i++) {
            if (idToVirginity[_maleList[i]] == false) {
                matedMaleList[matedMaleCount] = _maleList[i];
                matedMaleCount++;
            }
        }
        return matedMaleList;
    }

    function mint(address _user) public {
        _mint(_user, counter);
        idToVirginity[counter] = true;
        idToHousing[counter] = false;
        playerToMales[_user].push(counter);
        counter++;
    }

    function burn(address _user, uint256 _index) public {
        require(playerToMales[_user].length > 0, "index out of bound");
        uint256 _listIndex;
        for (uint256 i = 0; i < playerToMales[_user].length; i++) {
            if (playerToMales[_user][i] == _index) {
                _listIndex = i;
            }
        }
        playerToMales[_user][_listIndex] = playerToMales[_user][
            playerToMales[_user].length - 1
        ];
        playerToMales[_user].pop();
        _burn(_index);
    }

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) public {
        _setApprovalForAll(user, operator, approved);
    }
}
