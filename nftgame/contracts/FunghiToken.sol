//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FunghiToken is ERC20Upgradeable, OwnableUpgradeable {
    //constants
    uint256 cliffSize;
    uint256 cliffCount;
    uint256 maxSupply;
    uint256 public BURST_MULTIPLIER;
    uint256 public BASE_REWARD;

    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init("Funghi Token", "FUNGHI");
        BURST_MULTIPLIER = 5;
        BASE_REWARD = 80e18;
        cliffSize = 10000 * 1e18; //new cliff every 100,000 tokens
        cliffCount = 1000; // 1,000 cliffs
        maxSupply = 1000000 * 1e18; //100 mil max supply
    }

    function bondingCurve(uint256 earned_) public view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        uint256 currentCliff = totalSupply_ / cliffSize;

        if (currentCliff < cliffCount) {
            uint256 remaining = cliffCount - currentCliff;
            uint256 earned = (earned_ * remaining) / cliffCount;

            uint256 amountTillMax = maxSupply - totalSupply_;
            if (earned > amountTillMax) {
                earned = amountTillMax;
            }
            return earned;
        }
        return 0;
    }

    function mint(address _user, uint256 _amount) public {
        uint256 earned = bondingCurve(_amount * BASE_REWARD);
        _mint(_user, earned);
    }

    function burst(address _user) public {
        uint256 earned = bondingCurve(BURST_MULTIPLIER * BASE_REWARD);
        _mint(_user, earned);
    }

    function burn(address _user, uint256 _amount) public {
        _burn(_user, _amount);
    }

    function setApproval(
        address user,
        address spender,
        uint256 amount
    ) public {
        _approve(user, spender, amount);
    }
}
