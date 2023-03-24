//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Tournament.sol";

contract TournamentFactory is Initializable, OwnableUpgradeable {
    Tournament[] public tournaments;
    address[] public implementations;
    mapping(address => address[]) public userTournaments;

    function initialize(address[] calldata _implementations)
        public
        initializer
    {
        __Ownable_init();
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

    // function claimProfits() public onlyOwner {
    //     for (uint256 i = 0; i < tournaments.length; ++i) {
    //         Tournament tournament = Tournament(tournaments[i]).claimProfit();
    //         if (
    //             block.timestamp <
    //             tournament.startDate + tournament.tournamentDuration
    //         ) {
    //             Tournament(tournaments[i]).claimProfit();
    //         }
    //     }
    // }
}
