//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tournament.sol";

contract TournamentFactory is Ownable {
    Tournament[] public tournaments;
    address[] public implementations;
    mapping(address => address[]) public userTournaments;
    mapping(address => bool) private claimed;

    constructor(address[] memory _implementations) {
        for (uint256 i = 0; i < _implementations.length; i++) {
            implementations.push(_implementations[i]);
        }
    }

    function createTournament(
        string memory title,
        uint256 entranceFee,
        address currencyToken,
        uint256 startDate,
        uint256 maxParticipants,
        uint256 mode,
        uint256 speed
    ) public {
        require(maxParticipants > 4, "At least 4 players");
        require(startDate > block.timestamp, "Must be in future");
        require(mode == 0 || mode == 1 || mode == 2, "Wrong mode");
        require(speed == 0 || speed == 1 || speed == 2, "Wrong speed");
        Tournament tournament = new Tournament();
        tournament.initialize(
            title,
            entranceFee,
            currencyToken,
            startDate,
            maxParticipants,
            mode,
            speed,
            implementations
        );
        tournaments.push(tournament);
    }

    function getTournaments() public view returns (Tournament[] memory) {
        return tournaments;
    }

    function getUserTournaments() public view returns (address[] memory) {
        return userTournaments[msg.sender];
    }

    function claimProfits() public onlyOwner {
        for (uint256 i = 0; i < tournaments.length; ++i) {
            Tournament tournament_ = Tournament(tournaments[i]);
            if (
                block.timestamp <
                tournament_.startDate() + tournament_.tournamentDuration() &&
                claimed[address(tournament_)] == false
            ) {
                tournament_.claimProfit();
                claimed[address(tournament_)] = true;
            }
        }
    }
}
