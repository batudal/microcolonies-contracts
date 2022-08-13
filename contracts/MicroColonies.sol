//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Interfaces/ITournament.sol";

contract MicroColonies is Initializable {
    Schedule public schedule;
    Tariff public tariff;
    ITournament public tournament;
    uint256 private nonce;

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
        uint256 larvaPortion;
        uint256 queenPortion;
        uint256 conversionFee;
    }
    struct Q {
        uint256 level;
        uint256 eggs;
        uint256 timestamp;
        bool inNest;
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
        bool inNest;
    }
    struct S {
        uint256 hp; // 4..2 hp 1 zombie 0 null
        bool onMission;
        uint256 missionType;
        uint256 missionTimestamp;
        uint256 damageTimestamp;
        bool inNest;
    }
    struct M {
        bool onMission;
        bool inNest;
    }
    struct P {
        bool onMission;
        bool inNest;
    }
    struct Lolli {
        bool used;
        uint256 timestamp;
    }
    struct Mission {
        uint256 antType;
        uint256 id;
        uint256 timestamp;
    }

    /// @dev user => QLWSMP => ids
    mapping(address => mapping(uint256 => uint256[])) public userToids;
    mapping(address => Lolli) public lollipops;
    mapping(address => uint256) public funghiBalance;
    mapping(address => uint256) public feromonBalance;
    mapping(address => uint256) public capacity;
    mapping(address => uint256) public nested;
    mapping(address => Mission) public missions;

    /// @dev QLWSMP(012345) => counter;
    mapping(uint256 => uint256) counters;
    mapping(uint256 => Q) public q;
    mapping(uint256 => L) public l;
    mapping(uint256 => W) public w;
    mapping(uint256 => S) public s;
    mapping(uint256 => M) public m;
    mapping(uint256 => P) public p;

    uint256[3] public fert;

    modifier xp(uint256 _amount) {
        feromonBalance[msg.sender] += _amount;
        _;
    }

    function initialize() external initializer {
        tournament = ITournament(msg.sender);
        schedule.workerFarm = 1;
        schedule.workerBuild = 5;
        schedule.soldierRaid = 3;
        schedule.zombieGuard = 1;
        schedule.larvaHatch = 1;
        schedule.queenPeriod = 1;
        schedule.lollipopDuration = 1;
        nonce = 42;
        fert = [5, 9, 12];
    }

    // generalized fxns
    function getSpeed(address _user) public view returns (uint256 speed) {
        speed = lollipops[_user].timestamp + schedule.lollipopDuration >
            block.timestamp
            ? 2
            : 1;
    }

    function getAvailable(address _user, uint256 _type)
        public
        view
        returns (uint256[] memory available)
    {
        available = new uint256[](getLength(_user, _type));
        for (uint256 i; i < userToids[_user][_type].length; i++) {
            available[i] = userToids[_user][_type][i];
        }
    }

    function getLength(address _user, uint256 _type)
        public
        view
        returns (uint256 length)
    {
        length = userToids[_user][_type].length;
    }

    function openPack(address _user, uint256 _pack) public {
        require(msg.sender == address(tournament), "Only tournament can call.");
        if (_pack == 0) {
            _print(_user, 1, 20);
        } else if (_pack == 1) {
            _print(_user, 1, 15);
            _print(_user, 5, 1);
        } else if (_pack == 2) {
            _print(_user, 1, 10);
            _print(_user, 0, 1);
        }
    }

    function _kill(
        address _user,
        uint256 _type,
        uint256 _id
    ) private {
        userToids[_user][_type][_id] = userToids[_user][_type][
            userToids[_user][_type].length - 1
        ];
        userToids[_user][_type].pop();
    }

    function _print(
        address _user,
        uint256 _type,
        uint256 _amount
    ) private {
        for (uint256 i; i < _amount; i++) {
            userToids[_user][_type].push(counters[_type]);
            counters[_type]++;
        }
    }

    // worker fxns
    function convertToSoldier(uint256 _amount) public {
        uint256[] memory available = getAvailable(msg.sender, 2);
        require(_amount <= available.length, "Not enough workers.");
        require(
            _amount * tariff.conversionFee <= feromonBalance[msg.sender],
            "Not enough feromons."
        );
        for (uint256 i; i < available.length; i++) {
            _kill(msg.sender, 2, available[i]);
        }
        _print(msg.sender, 3, _amount);
    }

    function _hatch(address _user, uint256 _id) private {
        uint16 modulo = l[_id].fed ? 50 : 100;
        nonce =
            uint256(keccak256(abi.encodePacked(msg.sender, nonce))) %
            modulo;
        require(nested[_user] < capacity[_user]);
        if (nonce < 3) {
            p[counters[5]] = P(false, true);
            _print(_user, 5, 1);
        } else if (nonce >= 3 && nonce < 18) {
            m[counters[4]] = M(false, true);
            _print(_user, 4, 1);
        } else if (nonce >= 18 && nonce < 33) {
            s[counters[3]] = S(4, false, 0, 0, 0, true);
            _print(_user, 3, 1);
        } else {
            w[counters[2]] = W(5, false, 0, true);
            _print(_user, 2, 1);
        }
        _kill(_user, 1, _id);
        nested[_user]++;
    }

    // larva fxns
    function feedLarvae(uint256 _amount) public {
        uint256[] memory feedable = getFeedable(msg.sender);
        require(
            feedable.length >= _amount,
            "You don't have enough hungry larva"
        );
        require(
            funghiBalance[msg.sender] > _amount * tariff.larvaPortion,
            "You don't have enough $Funghi"
        );
        funghiBalance[msg.sender] -= tariff.larvaPortion * _amount;
        feromonBalance[msg.sender] += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            l[feedable[i]].fed = true;
        }
    }

    function getFeedable(address _user)
        public
        view
        returns (uint256[] memory feedable)
    {
        for (uint256 i; i < userToids[_user][1].length; i++) {
            if (l[userToids[_user][1][i]].fed) {
                feedable[i] = userToids[_user][1][i];
            }
        }
    }

    function hatch(uint256 _amount) public xp(_amount) {
        require(
            _amount <= nested[msg.sender],
            "You don't have enough nest capacity."
        );
        uint256[] memory larvae = userToids[msg.sender][1];
        require(_amount <= larvae.length);
        for (uint256 i = 0; i < larvae.length; i++) {
            _hatch(msg.sender, larvae[i]);
        }
    }

    function claimAllEggs() public {
        for (uint256 i; i < userToids[msg.sender][0].length; i++) {
            claimEggs(userToids[msg.sender][0][i]);
        }
    }

    function claimEggs(uint256 _id) public {
        uint256 deserved = eggsLaid(_id) - q[_id].eggs;
        require(deserved > 0, "No eggs laid yet.");
        q[_id].eggs += deserved;
        _print(msg.sender, 1, deserved);
        feromonBalance[msg.sender] += deserved;
    }

    function eggsLaid(uint256 _id) public returns (uint256 eggs) {
        uint256 epochs = (block.timestamp - q[_id].timestamp) /
            tournament.epochDuration();
        uint256 initEggs = fert[q[_id].level - 1];
        if (epochs > initEggs) {
            epochs = initEggs;
        }
        for (uint256 i = 0; i < epochs; i++) {
            eggs += initEggs;
            initEggs -= 1;
        }
    }

    function feedQueen(uint256 _id) public {
        claimEggs(_id);
        uint256 epochs = (block.timestamp - q[_id].timestamp) /
            tournament.epochDuration();
        uint256 amount = epochs * tariff.queenPortion;
        q[_id].timestamp = block.timestamp;
        q[_id].eggs = 0;
        funghiBalance[msg.sender] -= amount;
        feromonBalance[msg.sender] += epochs;
    }
}
