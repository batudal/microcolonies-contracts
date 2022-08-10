//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BondedToken is ERC20, Ownable {
    uint256 public immutable BURST_MULTIPLIER = 5;
    uint256 public immutable BASE_REWARD = 2400e18;

    constructor() ERC20("FunghiToken", "FUNGHI") {}

    //constants
    uint256 cliffSize = 10000 * 1e18;
    uint256 cliffCount = 1000;
    uint256 maxSupply = 10000000 * 1e18;

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

    function mint() public onlyOwner {
        uint256 earned = bondingCurve(BASE_REWARD);
        _mint(msg.sender, earned);
    }
}
