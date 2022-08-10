//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeromonToken is IERC20 {
    //vars
    function CONVERSION_FEE() external view returns (uint256);

    function QUEEN_UPGRADE_FEE() external view returns (uint256);

    //functions
    function mint(address _user, uint256) external;

    function initialize() external;

    function setApproval(
        address user,
        address spender,
        uint256 amount
    ) external;
}
