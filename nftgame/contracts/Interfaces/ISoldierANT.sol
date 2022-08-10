//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISoldierANT is IERC721 {
    //variables
    function RAID_EPOCHS() external view returns (uint256);

    function HEAL_EPOCHS() external view returns (uint256);

    function HEALING_FEE() external view returns (uint256);

    function MAX_DAMAGE_COUNT() external view returns (uint256);

    function duration() external view returns (uint256);

    //functions
    function addMission(
        address _user,
        uint256[] memory _ids,
        bool _finalized,
        uint256 speed
    ) external;

    function finalizeMission(address _user, uint256 _index) external;

    function getMissionEnd(address _user, uint256 _index)
        external
        view
        returns (uint256 _end);

    function getMissionParticipantList(address _user, uint256 _index)
        external
        view
        returns (uint256[] memory missionParticipants);

    function getMissionPartipants(address _user, uint256 _index)
        external
        view
        returns (uint256 missionParticipants);

    function battle(
        uint256 attackerSoldierCount,
        uint256 targetSoldierCount,
        uint256 targetLarvaeCount
    ) external returns (uint256 prize, uint256 bonus);

    function getAvailableSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function getZombieSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function getInfectedSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function getSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function setHousing(uint256 _index, bool _status) external;

    function setStaked(uint256 _index, bool _status) external;

    function infectionSpread(address _user) external;

    function setRaidMission(uint256 _index, bool _status) external;

    function setStakeDate(uint256 _index, uint256 _stakeDate) external;

    function setRaidDate(uint256 _index, uint256 _buildDate) external;

    function getHomelessCount(address _user) external view returns (uint256);

    function getUnHousedSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function increaseDamage(uint256 _index) external;

    function reduceDamage(uint256 _index, uint256 _damageReduced) external;

    function burn(address _user, uint256 _index) external;

    function mint(address _user) external;

    function initialize(
        uint256 epochDuration,
        address _lollipop,
        address _feromon,
        address _funghi
    ) external;

    //mappings
    function idToDamageCount(uint256) external view returns (uint256);

    function idToStakeDate(uint256) external view returns (uint256);

    function idToFinalDamageDate(uint256) external view returns (uint256);

    function idToRaidDate(uint256) external view returns (uint256);

    function idToStaked(uint256) external view returns (bool);

    function idToHousing(uint256) external view returns (bool);

    function idToOnRaidMission(uint256) external view returns (bool);

    function idToPassive(uint256) external view returns (bool);

    function playerToSoldiers(address) external view returns (uint256[] memory);

    function userMissions(address) external view returns (uint256[] memory);

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) external;
}
