//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FeromonToken is ERC20Upgradeable, OwnableUpgradeable {
    uint256 public DECIMAL;
    uint256 public CONVERSION_FEE;
    uint256 public QUEEN_UPGRADE_FEE;

    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init("Feromon Token", "FEROMON");
        DECIMAL = 1e18;
        CONVERSION_FEE = 10e18;
        QUEEN_UPGRADE_FEE = 100e18;
    }

    function mint(address _user, uint256 _amount) public {
        _mint(_user, _amount * DECIMAL);
    }

    function setApproval(
        address user,
        address spender,
        uint256 amount
    ) public {
        _approve(user, spender, amount);
    }
}
