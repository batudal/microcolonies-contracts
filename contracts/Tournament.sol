//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/ITournament.sol";
import "./Interfaces/IMicroColonies.sol";
import "./Interfaces/IModule.sol";
import "./Helpers/QuickStruct.sol";

contract Tournament is Initializable {
    uint256 immutable MAX_APPROVAL = 2**256 - 1;

    struct Contracts {
        address microColonies;
        address queen;
        address larva;
        address worker;
        address soldier;
        address princess;
        address zombie;
    }

    enum Mode {
        FEROMON,
        FUNGHI,
        POPULATION
    }

    Contracts public contracts;
    Mode public mode;
    uint256 public epochDuration;
    uint256 public tournamentDuration;
    string public tournamentTitle;
    uint256 public startDate;
    address public currencyToken;
    uint256 public entranceFee;
    address[] public participants;
    uint256[] public q_access = [0, 1, 2, 3, 4, 5, 6];
    uint256[] public l_access = [0, 1, 2, 3, 4, 5, 6];
    uint256[] public w_access = [0, 1, 2, 3, 4, 5, 6];
    uint256[] public s_access = [0, 1, 2, 3, 4, 5, 6];
    uint256[] public p_access = [0, 1, 2, 3, 4, 5, 6];
    uint256[] public z_access = [0, 1, 2, 3, 4, 5, 6];

    mapping(address => string) public nicknames;

    function initialize(
        string memory _tournamentTitle,
        uint256 _entranceFee,
        address _currencyToken,
        uint256 _epochDuration,
        uint256 _startDate,
        Mode _mode,
        address[] calldata _implementations
    ) public initializer {
        tournamentTitle = _tournamentTitle;
        epochDuration = _epochDuration;
        tournamentDuration = _epochDuration * 112;
        currencyToken = _currencyToken;
        entranceFee = _entranceFee;
        startDate = _startDate;
        mode = _mode;

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
        contracts.zombie = Clones.clone(_implementations[6]);
        IModule(contracts.zombie).initialize(contracts.microColonies);

        IMicroColonies(contracts.microColonies).setAccess(
            contracts.queen,
            q_access
        );
        IMicroColonies(contracts.microColonies).setAccess(
            contracts.larva,
            q_access
        );
        IMicroColonies(contracts.microColonies).setAccess(
            contracts.worker,
            q_access
        );
        IMicroColonies(contracts.microColonies).setAccess(
            contracts.soldier,
            q_access
        );
        IMicroColonies(contracts.microColonies).setAccess(
            contracts.princess,
            q_access
        );
        IMicroColonies(contracts.microColonies).setAccess(
            contracts.zombie,
            q_access
        );
    }

    function enterTournament(string memory _nickname) public {
        require(
            IERC20(currencyToken).balanceOf(msg.sender) >= entranceFee,
            "You don't have enough tokens."
        );
        require(block.timestamp >= startDate, "Tournament not started.");
        nicknames[msg.sender] = _nickname;
        IERC20(currencyToken).transferFrom(
            msg.sender,
            address(this),
            entranceFee
        );
        IMicroColonies(contracts.microColonies).openPack(msg.sender);
    }

    function getNickname(address _user)
        public
        view
        returns (string memory nickname)
    {
        nickname = nicknames[_user];
    }

    function scoreboard() public {}

    function sum(uint256[] memory data) internal pure returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < data.length; ++i) {
            total += data[i];
        }
        return total;
    }

    function getPlacement(address _user, uint256 _mode)
        public
        view
        returns (uint256)
    {
        QuickStruct.Participant[] memory ps = new QuickStruct.Participant[](
            participants.length
        );
        for (uint256 i = 0; i < participants.length; ++i) {
            if (_mode == 0) {
                // feromon
                ps[i].p_address = participants[i];
                ps[i].p_score = IMicroColonies(contracts.microColonies)
                    .feromonBalance(participants[i]);
            } else if (_mode == 1) {
                ps[i].p_address = participants[i];
                ps[i].p_score = IMicroColonies(contracts.microColonies)
                    .funghiBalance(participants[i]);
            } else if (_mode == 2) {
                ps[i].p_address = participants[i];
                uint256 total;
                for (uint256 j = 0; j <= 6; ++j) {
                    total += sum(
                        IMicroColonies(contracts.microColonies).counters(i)
                    );
                }
                ps[i].p_score = total;
            }
        }
        QuickStruct.Participant[] memory descending = QuickStruct
            .getDescendingStruct(ps);
        for (uint256 i = 0; i < descending.length; ++i) {
            if (descending[i].p_address == _user) {
                return i++;
            }
        }
        return 0;
    }

    function claimReward() public {}
}
