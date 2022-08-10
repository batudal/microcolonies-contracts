//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMaleANT is IERC721 {
    //variables
    function MATE_DURATION() external view returns (uint256);

    //functions
    function setMatingTime(uint256) external;

    function setMatingStatus(uint256 _index) external;

    function getMales(address _user) external view returns (uint256[] memory);

    function setHousing(uint256 _index, bool _status) external;

    function getHomelessCount(address _user) external view returns (uint256);

    function getUnHousedMales(address _user)
        external
        view
        returns (uint256[] memory);

    function getMatedMales(address _user)
        external
        view
        returns (uint256[] memory);

    function mint(address _user) external;

    function burn(address _user, uint256) external;

    //mappings
    function idToMateTime(uint256) external view returns (uint256);

    function playerToMales(address) external view returns (uint256[] memory);

    function idToHousing(uint256) external view returns (bool);

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) external;
}
