//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/ITournament.sol";
import "./Interfaces/IMicroColonies.sol";
import "./Interfaces/IModule.sol";

contract Tournament is Initializable {
    uint256 immutable MAX_APPROVAL = 2**256 - 1;

    struct Contracts {
        address microColonies;
        address queen;
        address larva;
        address worker;
        address soldier;
        address princess;
        address disaster;
    }

    Contracts public contracts;
    uint256 public epochDuration;
    uint256 public tournamentDuration;
    string public tournamentTitle;
    uint256 public startDate;
    address public currencyToken;
    uint256 public entranceFee;
    address[] public participants;

    mapping(address => string) public nicknames;

    // x -> 112x (epoch -> tournament)

    function initialize(
        string memory _tournamentTitle,
        address[] memory _participants,
        uint256 _entranceFee,
        address _currencyToken,
        uint256 _epochDuration,
        uint256 _startDate,
        address[] calldata _implementations
    ) public initializer {
        tournamentTitle = _tournamentTitle;
        tournamentDuration = _epochDuration * 112;
        currencyToken = _currencyToken;
        entranceFee = _entranceFee;
        startDate = _startDate;
        for (uint256 i = 0; i < _participants.length; i++) {
            participants.push(_participants[i]);
        }
        contracts.microColonies = Clones.clone(_implementations[0]);
        IMicroColonies(contracts.microColonies).initialize(_epochDuration);
        contracts.queen = Clones.clone(_implementations[1]);
        IModule(contracts.queen).initialize(contracts.microColonies);
        contracts.larva = Clones.clone(_implementations[2]);
        IModule(contracts.larva).initialize(contracts.microColonies);
        contracts.worker = Clones.clone(_implementations[3]);
        IModule(contracts.worker).initialize(contracts.microColonies);
        contracts.soldier = Clones.clone(_implementations[4]);
        IModule(contracts.soldier).initialize(contracts.microColonies);
        contracts.princess = Clones.clone(_implementations[5]);
        IModule(contracts.princess).initialize(contracts.microColonies);
        contracts.disaster = Clones.clone(_implementations[6]);
        IModule(contracts.disaster).initialize(contracts.microColonies);
    }

    modifier onlyParticipant() {
        bool access;
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == msg.sender) {
                access = true;
            }
        }
        require(access, "You don't have access.");
        _;
    }

    function enterTournament(string memory _nickname, uint256 _pack)
        public
        onlyParticipant
    {
        require(
            IERC20(currencyToken).balanceOf(msg.sender) > entranceFee,
            "You don't have enough tokens."
        );
        require(block.timestamp >= startDate, "Tournament not started.");
        nicknames[msg.sender] = _nickname;
        IMicroColonies(contracts.microColonies).openPack(msg.sender, _pack);
    }

    function getNickname(address _user)
        public
        view
        returns (string memory nickname)
    {
        nickname = nicknames[_user];
    }
}
