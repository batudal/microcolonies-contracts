//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PrincessANT is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public MATE_EPOCHS;
    uint256 public counter;
    uint256 public duration;
    bool public mating;

    struct Mission {
        uint256 start;
        uint256 end;
        uint256[] maleList;
        uint256[] princessList;
        bool finalized;
        uint256 speed;
    }
    mapping(address => Mission[]) public userMissions;

    function initialize(uint256 _epochDuration) public initializer {
        __Ownable_init();
        __ERC721_init("Princess Ant", "PRINCESS");
        MATE_EPOCHS = 1;
        duration = _epochDuration;
        counter = 1;
    }

    mapping(uint256 => uint256) public idToMateTime;
    mapping(uint256 => bool) public idToVirginity;
    mapping(uint256 => bool) public idToHousing;
    mapping(address => uint256[]) public playerToPrincesses;

    function getMissions(address _user) public view returns (Mission[] memory) {
        return userMissions[_user];
    }

    function getMissionIds(address _user, uint256 _missionIndex)
        public
        view
        returns (uint256[] memory princessList)
    {
        princessList = userMissions[_user][_missionIndex].princessList;
    }

    function addMission(
        address _user,
        uint256[] memory _maleList,
        uint256[] memory _princessList,
        bool _finalized,
        uint256 _speed
    ) public {
        mating = true;
        userMissions[_user].push(
            Mission({
                start: block.timestamp,
                end: block.timestamp + duration / _speed,
                maleList: _maleList,
                princessList: _princessList,
                finalized: _finalized,
                speed: _speed
            })
        );
    }

    function getMissionEnd(address _user, uint256 _missionIndex)
        public
        view
        returns (uint256 _end)
    {
        _end = userMissions[_user][_missionIndex].end;
        return _end;
    }

    function finalizeMission(address _user, uint256 _index) public {
        mating = false;
        userMissions[_user][_index].finalized = true;
    }

    function setMatingTime(uint256 _princessIndex) public {
        idToMateTime[_princessIndex] = block.timestamp;
    }

    function setMatingStatus(uint256 _index) public {
        idToVirginity[_index] = false;
    }

    function getPrincesses(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return playerToPrincesses[_user];
    }

    function setHousing(uint256 _index, bool _status) public {
        idToHousing[_index] = _status;
    }

    function getHomelessCount(address _user) public view returns (uint256) {
        uint256 _homeless = 0;
        uint256[] memory _princessList = playerToPrincesses[_user];
        for (uint256 i; i < _princessList.length; i++) {
            if (!idToHousing[_princessList[i]]) {
                _homeless += 1;
            }
        }
        return _homeless;
    }

    function getUnHousedPrincesses(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _princessList = getPrincesses(_user);
        uint256 _homelessCount = getHomelessCount(_user);
        uint256 _princessesHoused = 0;
        uint256[] memory _unhousedPrincessList = new uint256[](_homelessCount);
        for (uint256 i = 0; i < _princessList.length; i++) {
            if (!idToHousing[_princessList[i]]) {
                _unhousedPrincessList[_princessesHoused] = _princessList[i];
                _princessesHoused++;
            }
        }
        return _unhousedPrincessList;
    }

    function getMatedPrincesses(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _princessList = playerToPrincesses[_user];
        uint256 matedPrincessLength = 0;
        for (uint256 i; i < _princessList.length; i++) {
            if (idToVirginity[_princessList[i]] == false) {
                matedPrincessLength++;
            }
        }
        uint256[] memory matedPrincessList = new uint256[](matedPrincessLength);
        uint256 matedPrincessCount = 0;
        for (uint256 i; i < _princessList.length; i++) {
            if (idToVirginity[_princessList[i]] == false) {
                matedPrincessList[matedPrincessCount] = _princessList[i];
                matedPrincessCount++;
            }
        }
        return matedPrincessList;
    }

    function mint(address _user) public {
        _mint(_user, counter);
        idToVirginity[counter] = true;
        idToHousing[counter] = false;
        playerToPrincesses[_user].push(counter);
        counter++;
    }

    function burn(address _user, uint256 _index) public {
        require(playerToPrincesses[_user].length > 0, "index out of bound");
        uint256 _listIndex;
        for (uint256 i = 0; i < playerToPrincesses[_user].length; i++) {
            if (playerToPrincesses[_user][i] == _index) {
                _listIndex = i;
            }
        }
        playerToPrincesses[_user][_listIndex] = playerToPrincesses[_user][
            playerToPrincesses[_user].length - 1
        ];
        playerToPrincesses[_user].pop();

        _burn(_index);
    }

    function getClaimable(address _user, uint256 _missionIndex)
        public
        view
        returns (uint256 _claimable)
    {
        uint256 missionEnd = getMissionEnd(_user, _missionIndex);
        uint256 _now = block.timestamp;
        for (uint256 i = 0; i < userMissions[_user].length; i++) {
            if (missionEnd < _now) {
                _claimable++;
            }
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
