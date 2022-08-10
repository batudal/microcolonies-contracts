//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Interfaces/ITournament.sol";

contract MicroColonies is Initializable {
    Schedule public schedule;
    Tariff public tariff;
    ITournament public tournament;

    struct Schedule {
        uint8 workerFarm;
        uint8 workerBuild;
        uint8 soldierRaid;
        uint8 zombieGuard;
        uint8 larvaHatch;
        uint8 queenPeriod;
        uint8 lollipopDuration;
    }
    struct Tariff {
        uint16 larvaPortion;
    }
    struct Q {
        uint256 level;
        uint256 timestamp;
    }
    struct L {
        bool fed;
        uint256 timestamp;
        bool onMission;
    }
    struct W {
        uint8 hp;
        bool onMission;
        uint256 missionType;
    }
    struct S {
        uint256 hp; // 4..2 hp 1 zombie 0 null
        bool onMission;
        uint256 missionType;
        uint256 missionTimestamp;
        uint256 damageTimestamp;
    }
    struct M {
        bool onMission;
    }
    struct P {
        bool onMission;
    }
    struct Lolli {
        bool used;
        uint256 timestamp;
    }

    /// @dev user => QLWSMP => ids
    mapping(address => mapping(uint256 => uint256[])) public userToids;
    mapping(address => Lolli) public lollipops;
    mapping(address => uint256) public funghiBalance;
    mapping(address => uint256) public feromonBalance;

    /// @dev QLWSMP => counter;
    mapping(uint256 => uint256) counters;

    /// @notice struct mappings
    mapping(uint256 => Q) public q;
    mapping(uint256 => L) public l;
    mapping(uint256 => W) public w;
    mapping(uint256 => S) public s;
    mapping(uint256 => M) public m;
    mapping(uint256 => P) public p;

    function initialize() external initializer {
        tournament = ITournament(msg.sender);
        schedule.workerFarm = 1;
        schedule.workerBuild = 5;
        schedule.soldierRaid = 3;
        schedule.zombieGuard = 1;
        schedule.larvaHatch = 1;
        schedule.queenPeriod = 1;
        schedule.lollipopDuration = 1;
    }

    function getSpeed(address _user) public view returns (uint256 speed) {
        require(lollipops[_user].used, "Lollipop not used yet.");
        speed = lollipops[_user].timestamp + schedule.lollipopDuration >
            block.timestamp
            ? 2
            : 1;
    }

    function convertFromWorkerToSoldier(uint256 _amount) public {
        uint256[] memory workers = worker.getAvailableWorkers(msg.sender);
        require(_amount <= workers.length, "Not enough workers.");
        require(
            _amount * feromon.CONVERSION_FEE() <= feromon.balanceOf(msg.sender),
            "Not enough feromons."
        );
        for (uint256 i = 0; i < _amount; i++) {
            feromon.transferFrom(
                msg.sender,
                address(this),
                feromon.CONVERSION_FEE()
            );
            worker.burn(msg.sender, workers[i]);
            soldier.mint(msg.sender);
        }
    }

    function openPack(address _user, uint256 _pack) public {
        require(msg.sender == address(tournament), "Only tournament can call.");
        if (_pack == 0) {
            print(_user, 1, 40);
        } else if (_pack == 1) {
            print(_user, 1, 20);
            print(_user, 5, 1);
        } else if (_pack == 2) {
            print(_user, 1, 10);
            print(_user, 0, 1);
        }
    }

    function print(
        address _user,
        uint256 _type,
        uint256 _amount
    ) private {
        for (uint256 i; i < _amount; i++) {
            userToids[_user][_type].push(counters[_type]);
            counters[_type]++;
        }
    }

    // larva fxns
    function feedLarvae(uint256 _amount) public {
        uint256[] feedable = getFeedable(msg.sender);
        require(
            feedable.length >= _amount,
            "You don't have enough hungry larva"
        );
        require(
            funghiBalance > _amount * tariff.larvaPortion,
            "You don't have enough $Funghi"
        );
        funghiBalance -= tariff.larvaPortion * _amount;
        feromonBalance += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            l[feedable[i]].fed = true;
        }
    }

    function getFeedable(address _user)
        public
        returns (uint256[] memory feedable)
    {
        for (uint256 i; i < userToids[_user][1].length; i++) {
            if (l[userToids[_user][1][i]].fed) {
                feedable[i] = userToids[_user][1][i];
            }
        }
    }
}
