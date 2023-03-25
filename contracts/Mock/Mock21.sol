// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Mock21 is ERC20 {
    constructor() ERC20("Mock Token", "M0CK") {}

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
