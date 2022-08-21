//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITournament {
    function epochDuration() external view returns (uint256);

    function tournamentDuration() external view returns (uint256);

    function startDate() external view returns (uint256);

    function participants() external view returns (address[] calldata);

    function token() external view returns (address);

    function treasury() external view returns (address);
}
