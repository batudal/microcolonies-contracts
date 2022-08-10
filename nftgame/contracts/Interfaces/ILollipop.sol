//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILollipop is IERC721 {
    function initialize(uint256 epochDuration) external;

    //mappings
    function idToTimestamp(uint256) external view returns (uint256);

    function mint(address _user) external;

    function activate(address _user) external;

    function burn(address _user) external;

    function playerToLollipopId(address _user) external view returns (uint256);

    function duration() external view returns (uint256);

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) external;
}
