//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAnt {
    function initialize(
        address _queenAddress,
        address _larvaAddress,
        address _workerAddress,
        address _soldierAddress,
        address _maleAddress,
        address _princessAddress,
        address _lollipopAddress,
        address _funghiAddress,
        address _feromonAddress,
        uint256 _tournamentDuration,
        uint256 _startDate
    ) external;

    function addParticipants(address[] memory _participants) external;

    function increaseAvailableSpace(address _user) external;

    function getSeasonBonus() external view returns (uint256 bonus);

    function getNextSeason() external view returns (uint256);

    function startDate() external view returns (uint256);
}
