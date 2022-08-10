//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Interfaces/ILollipop.sol";
import "./Interfaces/IFeromonToken.sol";
import "./Interfaces/IFunghiToken.sol";
import "./Interfaces/IAnt.sol";
import "hardhat/console.sol";

contract WorkerANT is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public counter;
    uint256 public STAKE_EPOCHS;
    uint256 public BUILD_EPOCHS;
    uint256 public duration;
    address public lollipop;
    address public feromon;
    address public funghi;
    address public ant;

    function initialize(
        uint256 _epochDuration,
        address _lollipop,
        address _feromon,
        address _funghi,
        address _ant
    ) public initializer {
        __Ownable_init();
        __ERC721_init("Soldier Ant", "SOLDIER");
        duration = _epochDuration;
        STAKE_EPOCHS = 1;
        BUILD_EPOCHS = 5;
        counter = 1;
        lollipop = _lollipop;
        feromon = _feromon;
        funghi = _funghi;
        ant = _ant;
    }

    mapping(uint256 => uint256) public idToHealthPoints;
    mapping(uint256 => uint256) public idToStakeDate;
    mapping(uint256 => uint256) public idToBuildDate;
    mapping(uint256 => bool) public idToStaked;
    mapping(uint256 => bool) public idToProtected;
    mapping(uint256 => bool) public idToHousing;
    mapping(uint256 => bool) public idToOnBuildMission;
    mapping(address => uint256[]) public playerToWorkers;

    struct Mission {
        uint256 start;
        uint256 end;
        uint256[] ids;
        uint256 missionType; // 0-stake, 1-build
        bool finalized;
    }
    mapping(address => Mission[]) public userMissions;

    // contract functions

    function getMissions(address _user) public view returns (Mission[] memory) {
        return userMissions[_user];
    }

    function getMissionIds(address _user, uint256 _missionIndex)
        public
        view
        returns (uint256[] memory ids)
    {
        ids = userMissions[_user][_missionIndex].ids;
    }

    function getMissionEnd(address _user, uint256 _missionIndex)
        public
        view
        returns (uint256 _end)
    {
        _end = userMissions[_user][_missionIndex].end;
        return _end;
    }

    function getSpeed(address _user) public view returns (uint256 speed) {
        uint256 _id = IERC721(address(lollipop)).balanceOf(_user);
        uint256 _now = block.timestamp;
        uint256 _time = ILollipop(lollipop).idToTimestamp(_id);
        uint256 _duration = ILollipop(lollipop).duration();
        if (_time + _duration > _now) {
            speed = 2;
        } else {
            speed = 1;
        }
    }

    function stakeWorker(uint256 _amount) public {
        uint256[] memory availableWorkerList = getAvailableWorkers(msg.sender);
        require(_amount <= availableWorkerList.length);
        uint256[] memory workerList = new uint256[](_amount);
        uint256 _workerOnMission = 0;
        for (uint256 i; i < _amount; i++) {
            setStaked(availableWorkerList[i], true);
            setStakeDate(availableWorkerList[i], block.timestamp);
            _transfer(msg.sender, address(this), availableWorkerList[i]);
            workerList[_workerOnMission] = availableWorkerList[i];
            _workerOnMission++;
            IFeromonToken(feromon).mint(msg.sender, 1);
        }
        uint256 speed = getSpeed(msg.sender);
        addMission(msg.sender, workerList, 0, false, speed);
    }

    function claimFunghi(uint256 _missionIndex) public {
        uint256[] memory workersOnMission = getMissionIds(
            msg.sender,
            _missionIndex
        );
        uint256 missionEnd = getMissionEnd(msg.sender, _missionIndex);
        for (uint256 i; i < workersOnMission.length; i++) {
            if (missionEnd <= block.timestamp) {
                IFunghiToken(funghi).mint(msg.sender, 1);
                _transfer(address(this), msg.sender, workersOnMission[i]);
                reduceHP(msg.sender, workersOnMission[i]);
                setStaked(workersOnMission[i], false);
            }
        }
        finalizeMission(msg.sender, _missionIndex);
    }

    function addMission(
        address _user,
        uint256[] memory _ids,
        uint256 _missionType,
        bool _finalized,
        uint256 speed
    ) public {
        userMissions[_user].push(
            Mission({
                start: block.timestamp,
                end: block.timestamp +
                    (
                        _missionType == 1
                            ? (BUILD_EPOCHS * duration) / speed
                            : (STAKE_EPOCHS * duration) / speed
                    ),
                ids: _ids,
                missionType: _missionType,
                finalized: _finalized
            })
        );
    }

    function finalizeMission(address _user, uint256 _index) public {
        userMissions[_user][_index].finalized = true;
    }

    function getWorkers(address _user) public view returns (uint256[] memory) {
        return playerToWorkers[_user];
    }

    function getAvailableWorkers(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256 workerCounter;
        uint256[] memory _workerList = playerToWorkers[_user];
        uint256 _builderCount;
        uint256 _stakedWorkerCount;
        for (uint256 i = 0; i < _workerList.length; i++) {
            if (idToOnBuildMission[_workerList[i]]) {
                _builderCount += 1;
            } else if (idToStaked[_workerList[i]]) {
                _stakedWorkerCount += 1;
            }
        }
        uint256[] memory availableWorkerList = new uint256[](
            _workerList.length - _stakedWorkerCount - _builderCount
        );
        for (uint256 i; i < _workerList.length; i++) {
            if (
                !idToStaked[_workerList[i]] &&
                !idToOnBuildMission[_workerList[i]]
            ) {
                availableWorkerList[workerCounter] = _workerList[i];
                workerCounter++;
            }
        }
        return availableWorkerList;
    }

    function getUnHousedWorkers(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _workersList = getWorkers(_user);
        uint256 _homelessCount = getHomelessCount(_user);
        uint256 _workersHoused = 0;
        uint256[] memory _unhousedWorkerList = new uint256[](_homelessCount);
        for (uint256 i = 0; i < _workersList.length; i++) {
            if (!idToHousing[_workersList[i]]) {
                _unhousedWorkerList[_workersHoused] = _workersList[i];
                _workersHoused++;
            }
        }
        return _unhousedWorkerList;
    }

    function getHomelessCount(address _user) public view returns (uint256) {
        uint256 _homeless = 0;
        uint256[] memory _workerList = playerToWorkers[_user];
        for (uint256 i; i < _workerList.length; i++) {
            if (!idToHousing[_workerList[i]]) {
                _homeless += 1;
            }
        }
        return _homeless;
    }

    function setStaked(uint256 _index, bool _status) public {
        idToStaked[_index] = _status;
    }

    function setHousing(uint256 _index, bool _status) public {
        idToHousing[_index] = _status;
    }

    function setProtected(uint256 _index, bool _status) public {
        idToProtected[_index] = _status;
    }

    function setBuildMission(uint256 _index, bool _status) public {
        idToOnBuildMission[_index] = _status;
    }

    function setHP(uint256 _index, uint256 _healthPoints) public {
        idToHealthPoints[_index] = _healthPoints;
    }

    function setStakeDate(uint256 _index, uint256 _stakeDate) public {
        idToStakeDate[_index] = _stakeDate;
    }

    function setBuildDate(uint256 _index, uint256 _buildDate) public {
        idToBuildDate[_index] = _buildDate;
    }

    function getClaimableFunghi(address _user)
        public
        view
        returns (uint256 _funghiAmount)
    {
        uint256[] memory _workerList = playerToWorkers[_user];
        uint256 _claimableFunghi;
        for (uint256 i = 0; i < _workerList.length; i++) {
            if (
                idToStaked[_workerList[i]] &&
                STAKE_EPOCHS * duration <=
                block.timestamp - idToStakeDate[_workerList[i]]
            ) {
                _claimableFunghi += 240;
            }
        }
        return _claimableFunghi;
    }

    function getClaimableBB(address _user)
        public
        view
        returns (uint256 _claimableBB)
    {
        uint256[] memory _workerList = playerToWorkers[_user];
        for (uint256 i = 0; i < _workerList.length; i++) {
            if (
                idToOnBuildMission[_workerList[i]] &&
                BUILD_EPOCHS * duration <=
                block.timestamp - idToBuildDate[_workerList[i]]
            ) {
                _claimableBB++;
            }
        }
        return _claimableBB;
    }

    function reduceHP(address _user, uint256 _index) public {
        if (idToProtected[_index] == false) {
            if (idToHealthPoints[_index] > 2) {
                idToHealthPoints[_index] -= 2;
            } else {
                killWorker(_user, _index);
            }
        } else {
            if (idToHealthPoints[_index] > 1) {
                idToHealthPoints[_index] -= 1;
            } else {
                killWorker(_user, _index);
            }
        }
    }

    function killWorker(address _user, uint256 _index) public {
        require(playerToWorkers[_user].length > 0, "index out of bound");

        uint256 _listIndex;
        for (uint256 i = 0; i < playerToWorkers[_user].length; i++) {
            if (playerToWorkers[_user][i] == _index) {
                _listIndex = i;
            }
        }
        playerToWorkers[_user][_listIndex] = playerToWorkers[_user][
            playerToWorkers[_user].length - 1
        ];
        playerToWorkers[_user].pop();
        _burn(_index);
        if (idToHousing[_index]) {
            IAnt(ant).increaseAvailableSpace(_user);
        }
        idToHousing[_index] = false;
        idToProtected[_index] = false;
    }

    function burn(address _user, uint256 _index) public {
        require(playerToWorkers[_user].length > 0, "index out of bound");
        uint256 _listIndex;
        for (uint256 i = 0; i < playerToWorkers[_user].length; i++) {
            if (playerToWorkers[_user][i] == _index) {
                _listIndex = i;
            }
        }
        playerToWorkers[_user][_listIndex] = playerToWorkers[_user][
            playerToWorkers[_user].length - 1
        ];
        playerToWorkers[_user].pop();
        _burn(_index);
    }

    function mint(address _user) public {
        idToHealthPoints[counter] = 10;
        idToStaked[counter] = false;
        idToOnBuildMission[counter] = false;
        idToProtected[counter] = false;
        idToHousing[counter] = false;

        _mint(_user, counter);
        playerToWorkers[_user].push(counter);
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
