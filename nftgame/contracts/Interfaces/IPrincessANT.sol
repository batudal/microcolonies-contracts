//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPrincessANT is IERC721 {
    //variables
    function MATE_EPOCHS() external view returns (uint256);

    function duration() external view returns (uint256);

    //functions
    function addMission(
        address _user,
        uint256[] memory _maleList,
        uint256[] memory _princessList,
        bool _finalized,
        uint256 _speed
    ) external;

    function finalizeMission(address _user, uint256 _index) external;

    function getMissionEnd(address _user, uint256 _missionIndex)
        external
        view
        returns (uint256 _end);

    function getMissionIds(address _user, uint256 _missionIndex)
        external
        view
        returns (uint256[] memory princessList);

    function setMatingTime(uint256) external;

    function setMatingStatus(uint256 _index) external;

    function getPrincesses(address _user)
        external
        view
        returns (uint256[] memory);

    function getMatedPrincesses(address _user)
        external
        view
        returns (uint256[] memory);

    function setHousing(uint256 _index, bool _status) external;

    function getHomelessCount(address _user) external view returns (uint256);

    function getUnHousedPrincesses(address _user)
        external
        view
        returns (uint256[] memory);

    function getClaimable(address _user, uint256 _missionIndex)
        external
        view
        returns (uint256 _claimable);

    function mint(address _user) external;

    function burn(address _user, uint256) external;

    function initialize(uint256 epochDuration) external;

    //mappings
    function idToMateTime(uint256) external view returns (uint256);

    function playerToPrincesses(address)
        external
        view
        returns (uint256[] memory);

    function idToVirginity(uint256) external view returns (bool);

    function idToHousing(uint256) external view returns (bool);

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) external;

    function mating() external view returns (bool);
}
