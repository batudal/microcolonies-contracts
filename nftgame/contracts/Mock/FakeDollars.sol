//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeDollars is ERC20 {
    constructor(address _larva) ERC20("fakeDollars","fDollars") {
        _mint(_larva, 800e18);
    }
}

