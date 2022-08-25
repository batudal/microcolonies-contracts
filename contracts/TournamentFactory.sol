//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Tournament.sol";
import "hardhat/console.sol";

contract TournamentFactory is Initializable {
    Tournament[] public tournaments;
    address[] public implementations;
    mapping(address => address[]) public userTournaments;

    function initialize(address[] calldata _implementations) public initializer {
        // require(_implementations.length == 7);
        for (uint256 i = 0; i < _implementations.length; i++) {
            implementations.push(_implementations[i]);
        }
    }

    function createTournament(
        string memory title,
        address[] memory participants,
        uint256 entranceFee,
        address currencyToken,
        uint256 epochDuration,
        uint256 startDate
    ) public {
        Tournament tournament = new Tournament();
        tournament.initialize(
            title,
            participants,
            entranceFee,
            currencyToken,
            epochDuration,
            startDate,
            implementations
        );
        tournaments.push(tournament);
        for (uint256 i = 0; i < participants.length; i++) {
            userTournaments[participants[i]].push(address(tournament));
        }
    }

    function getTournaments() public view returns (Tournament[] memory) {
        return tournaments;
    }

    function getUserTournaments() public view returns (address[] memory) {
        return userTournaments[msg.sender];
    }
}
