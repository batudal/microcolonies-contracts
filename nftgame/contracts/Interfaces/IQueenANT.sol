//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IQueenANT is IERC721 {
    //variables
    function FERTILITY_DURATION() external view returns (uint256);

    function PORTION_FEE() external view returns (uint256);

    //functions
    function getQueens(address _user) external view returns (uint256[] memory);

    function setEggCount(uint256 _index, uint256 _eggCount) external;

    function setFertility(uint256 _index, bool _value) external;

    function setFertilityPoints(uint256 _index, uint256 _fertility) external;

    function resetEggCount(uint256 _index) external;

    function eggsFormula(uint256 _index)
        external
        view
        returns (uint256 _totalEggs);

    function getEpoch(uint256 _index) external view returns (uint256);

    function setTimestamp(uint256 _index, uint256 _timestamp) external;

    function setHousing(uint256 _index, bool _status) external;

    function getHomelessCount(address _user) external view returns (uint256);

    function getUnHousedQueens(address _user)
        external
        view
        returns (uint256[] memory);

    function queenLevelup(uint256 _index) external;

    function feedQueen(uint256 _index) external;

    function mint(address _user) external;

    function initialize(uint256 _epochDuration) external;

    //mappings
    function idToTimestamp(uint256) external view returns (uint256);

    function idToLevel(uint256) external view returns (uint256);

    function idToEggs(uint256) external view returns (uint256);

    function idToHousing(uint256) external view returns (bool);

    function idToFertilityPoints(uint256) external view returns (uint256);

    function playerToQueens(address) external view returns (uint256[] memory);

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) external;
}
