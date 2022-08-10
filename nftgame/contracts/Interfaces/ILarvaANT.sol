//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILarvaANT is IERC721 {
    //variables
    function genesisCounter() external view returns (uint256);

    function PORTION_FEE() external view returns (uint256);

    function FOOD() external view returns (uint256);

    function MAX_GENESIS_MINT() external view returns (uint256);

    function LARVA_PRICE() external view returns (uint256);

    function HATCH_DURATION() external view returns (uint256);

    function MAX_GENESIS_PER_TX() external view returns (uint256);

    //functions
    function feedingLarva(
        address _user,
        uint256 _larvaAmount,
        uint256 _index
    ) external;

    function getLarvae(address _user) external view returns (uint256[] memory);

    // function getLarvaCount() external view returns(uint256);
    function genesisMint(uint256 amount) external payable;

    function getFeedable(address _user)
        external
        view
        returns (uint256 feedable);

    function getHungryLarvae(address _user)
        external
        view
        returns (uint256[] memory _hungryLarvae);

    function setResourceCount(uint256 _index, uint256 _amount) external;

    function getHatchersLength(address _user) external view returns (uint256);

    function getStolen(
        address _target,
        address _user,
        uint256 _larvaId
    ) external;

    function mint(address _user, uint256 _amount) external;

    function burn(address _user, uint256 _index) external;

    function drain() external;

    function initialize(uint256 epochDuration) external;

    //mappings
    function idToSpawnTime(uint256) external view returns (uint256);

    function idToResource(uint256) external view returns (uint256);

    function idToFed(uint256) external view returns (bool);

    function playerToLarvae(address) external view returns (uint256[] memory);

    function setupApprovals(
        address user,
        address operator,
        bool approved
    ) external;
}
