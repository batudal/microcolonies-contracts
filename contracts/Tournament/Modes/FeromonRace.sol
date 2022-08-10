//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FeromonRace is Initializable {
    uint256 immutable MAX_APPROVAL = 2**256 - 1;

    struct Contracts {
        address contractAnt;
        address contractQueen;
        address contractLarva;
        address contractWorker;
        address contractSoldier;
        address contractMale;
        address contractPrincess;
        address contractLollipop;
        address contractFunghi;
        address contractFeromon;
    }
    Contracts public contracts;

    uint256 public tournamentDuration;
    string public tournamentTitle;
    uint256 public startDate;
    address public currencyToken;
    uint256 public entranceFee;
    address[] public implementations = new address[](10);
    address[] public participants;

    mapping(address => string) public nicknames;

    function initialize(
        string memory _tournamentTitle,
        address[] memory _participants,
        uint256 _entranceFee,
        address _currencyToken,
        uint256 _epochDuration,
        uint256 _tournamentDuration,
        uint256 _startDate,
        address[] memory _implementations
    ) public initializer {
        tournamentTitle = _tournamentTitle;
        tournamentDuration = _tournamentDuration;
        currencyToken = _currencyToken;
        entranceFee = _entranceFee;
        startDate = _startDate;
        // clone and initialize subcontracts
        for (uint256 i = 0; i < _participants.length; i++) {
            participants.push(_participants[i]);
        }
    }

    function enterTournament(string memory nickname) public payable {
        require(msg.value == entranceFee, "Pay to enter.");
        require(block.timestamp >= startDate, "Tournament not started.");
        bool access = false;
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == msg.sender) {
                access = true;
            }
        }
        require(access == true, "No access.");
        nicknames[msg.sender] = nickname;
        setApprovals(msg.sender);
        sendPack(msg.sender);
    }

    function sendPack(address _user) internal {
        ILarvaANT(contracts.contractLarva).mint(_user, 10);
        ILollipop(contracts.contractLollipop).mint(_user);
    }

    function distributeRewards() public {
        require(
            startDate + tournamentDuration < block.timestamp,
            "Race isn't over yet."
        );
        address _funghiWinner = funghiWinner();
        address _feromonWinner = feromonWinner();
        address _populationWinner = populationWinner();
        uint256 rewardAmount = 266 * 1e18;
        IERC20(currencyToken).transferFrom(
            address(this),
            _funghiWinner,
            rewardAmount
        );
        IERC20(currencyToken).transferFrom(
            address(this),
            _feromonWinner,
            rewardAmount
        );
        IERC20(currencyToken).transferFrom(
            address(this),
            _populationWinner,
            rewardAmount
        );
    }

    function funghiWinner() internal view returns (address) {
        address _winner;
        uint256 _winnerBalance;
        for (uint256 i; i < 8; i++) {
            uint256 _balance = IERC20(contracts.contractFunghi).balanceOf(
                participants[i]
            );
            _winner = _balance > _winnerBalance ? participants[i] : _winner;
        }
        return _winner;
    }

    function feromonWinner() internal view returns (address) {
        address _winner;
        uint256 _winnerBalance;
        for (uint256 i; i < 8; i++) {
            uint256 _balance = IERC20(contracts.contractFeromon).balanceOf(
                participants[i]
            );
            _winner = _balance > _winnerBalance ? participants[i] : _winner;
        }
        return _winner;
    }

    function populationWinner() internal view returns (address) {
        address _winner;
        uint256 _winnerBalance;
        for (uint256 i; i < 8; i++) {
            uint256 _balance;
            _balance += IERC721(contracts.contractWorker).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractSoldier).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractQueen).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractLarva).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractMale).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractPrincess).balanceOf(
                participants[i]
            );
            _winner = _balance > _winnerBalance ? participants[i] : _winner;
        }
        return _winner;
    }

    function getNickname(address _user)
        public
        view
        returns (string memory nickname)
    {
        nickname = nicknames[_user];
    }
}
