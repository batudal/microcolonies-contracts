//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Tournament.sol";

contract TournamentFactory {
    Tournament[] public tournaments;
    address[] public implementations = new address[](10);
    mapping(address => address[]) public userTournaments;

    constructor(address[] memory _implementations) {
        require(_implementations.length == 10);
        for (uint256 i = 0; i < _implementations.length; i++) {
            implementations[i] = _implementations[i];
        }
    }

    function createTournament(
        string memory title,
        address[] memory participants,
        uint256 entranceFee,
        address currencyToken,
        uint256 epochDuration,
        uint256 tournamentDuration,
        uint256 startDate
    ) public {
        Tournament tournament = new Tournament();
        tournament.initialize(
            title,
            participants,
            entranceFee,
            currencyToken,
            epochDuration,
            tournamentDuration,
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
        address[] memory t = userTournaments[msg.sender];
        return t;
    }
}
