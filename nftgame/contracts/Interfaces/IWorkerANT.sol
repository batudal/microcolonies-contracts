//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWorkerANT is IERC721 {
    //variables
    function BUILD_EPOCHS() external view returns (uint256);

    function STAKE_EPOCHS() external view returns (uint256);

    function duration() external view returns (uint56);

    //functions
    function addMission(
        address _user,
        uint256[] memory _ids,
        uint256 _missionType,
        bool _finalized,
        uint256 speed
    ) external;

    function getWorkers(address _user) external view returns (uint256[] memory);

    function getAvailableWorkers(address _user)
        external
        view
        returns (uint256[] memory);

    function getUnHousedWorkers(address _user)
        external
        view
        returns (uint256[] memory);

    function getHomelessCount(address _user) external view returns (uint256);

    function finalizeMission(address _user, uint256 _index) external;

    function setStaked(uint256 _index, bool _status) external;

    function setHousing(uint256 _index, bool _status) external;

    function setProtected(uint256 _index, bool _status) external;

    function setBuildMission(uint256 _index, bool _status) external;

    function setHP(uint256 _index, uint256 _healthPoints) external;

    function setStakeDate(uint256 _index, uint256 _stakeDate) external;

    function setBuildDate(uint256 _index, uint256 _buildDate) external;

    function getMissionIds(address _user, uint256 _missionIndex)
        external
        view
        returns (uint256[] memory ids);

    function getMissionEnd(address _user, uint256 _missionIndex)
        external
        view
        returns (uint256 _end);

    function getClaimableFunghi(address _user)
        external
        view
        returns (uint256 _funghiAmount);

    function getClaimableBB(address _user)
        external
        view
        returns (uint256 _claimableBB);

    function reduceHP(address _user, uint256 _index) external;

    function burn(address _user, uint256 _index) external;

    function mint(address _user) external;

    function getAvailableSpace(address _user)
        external
        view
        returns (uint256 capacity);

    function increaseCapacity(address _user) external;

    function decreaseAvailableSpace(address _user) external;

    function inreaseAvailableSpace(address _user) external;

    function initialize(
        uint256 epochDuration,
        address _lollipop,
        address _feromon,
        address _funghi,
        address _ant
    ) external;

    //mappings
    function idToHealthPoints(uint256) external view returns (uint256);

    function idToStakeDate(uint256) external view returns (uint256);

    function idToBuildDate(uint256) external view returns (uint256);

    function idToStaked(uint256) external view returns (bool);

    function idToProtected(uint256) external view returns (bool);

    function idToHousing(uint256) external view returns (bool);

    function idToOnBuildMission(uint256) external view returns (bool);

    function playerToWorkers(address) external view returns (uint256[] memory);

    struct Mission {
        uint256 start;
        uint256 end;
        uint256[] ids;
        uint256 missionType; // 0-stake, 1-build
        bool finalized;
    }

    function userMissions(address) external view returns (Mission[] memory);

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) external;
}
