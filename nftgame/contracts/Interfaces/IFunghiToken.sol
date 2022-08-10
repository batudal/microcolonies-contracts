//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFunghiToken is IERC20 {
    //functions
    function mint(address _user, uint256 _amount) external;

    function burst(address _user) external;

    function initialize() external;

    function burn(address _user, uint256 _amount) external;

    function setApproval(
        address user,
        address spender,
        uint256 amount
    ) external;
}
