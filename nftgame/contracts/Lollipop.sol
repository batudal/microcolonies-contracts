//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Lollipop is ERC721Upgradeable, OwnableUpgradeable {
    uint256 counter;
    uint256 public duration;
    mapping(uint256 => uint256) public idToTimestamp;
    mapping(address => uint256) public playerToLollipopId;

    function initialize(uint256 _tournamentDuration) public initializer {
        __Ownable_init();
        __ERC721_init("Lollipop Booster", "LOLLIPOP");
        unchecked {
            duration = _tournamentDuration / 4;
        }
    }

    function mint(address _user) public {
        counter++;
        _mint(_user, counter);
        playerToLollipopId[_user] = counter;
    }

    function activate(address _user) public {
        require(
            ownerOf(playerToLollipopId[_user]) == _user,
            "You are not the owner."
        );
        require(
            idToTimestamp[playerToLollipopId[_user]] == 0,
            "Already activated."
        );
        idToTimestamp[playerToLollipopId[_user]] = block.timestamp;
        _burn(playerToLollipopId[_user]);
    }

    function getTimeLeft(address _user) public view returns (uint256 timeleft) {
        uint256 _now = block.timestamp;
        uint256 _timestamp = idToTimestamp[playerToLollipopId[_user]];
        if (_now > _timestamp + duration) {
            timeleft = 0;
        } else {
            timeleft = _timestamp + duration - _now;
        }
    }

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) public {
        _setApprovalForAll(user, operator, approved);
    }
}
