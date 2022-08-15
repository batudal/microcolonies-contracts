//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Interfaces/ITournament.sol";
import "./Helpers/Quick.sol";

contract MicroColonies is Initializable, OwnableUpgradeable {
    Schedule public schedule;
    Tariff public tariff;
    ITournament public tournament;
    uint256 private nonce;

    struct Schedule {
        uint8 workerFarm;
        uint8 workerBuild;
        uint8 conversion;
        uint8 soldierRaid;
        uint256 zombification;
        uint8 zombieHarvest;
        uint8 zombieGuard;
        uint8 incubation;
        uint8 queenPeriod;
        uint8 lollipopDuration;
    }
    struct Tariff {
        uint256 larvaPortion;
        uint256 queenPortion;
        uint256 queenUpgrade;
        uint256 conversion;
        uint256 zombieHarvest;
        uint256 farmReward;
        uint256 buildReward;
    }
    struct Q {
        uint256 level;
        uint256 eggs;
        uint256 timestamp;
        bool inNest;
    }
    struct L {
        Mission mission; // missionType (0-unfed, 1-fed)
    }
    struct W {
        uint8 hp;
        Mission mission; // missionType (0-farm, 1-build, 2-conversion)
        bool inNest;
    }
    struct S {
        uint256 hp; // 4..2 hp 1 zombie 0 null
        Mission mission; // missionType (0-scout, 1-harvest, 2-defend)
        uint256 damageTimestamp;
        bool inNest;
    }
    struct M {
        Mission mission;
        bool inNest;
    }
    struct P {
        Mission mission;
        bool inNest;
    }
    struct Lolli {
        bool used;
        uint256 timestamp;
    }

    struct Mission {
        uint256 missionId;
        uint256 missionType;
        uint256 missionTimestamp;
        bool missionFinalized;
    }

    /// @dev user => QLWSMP => ids
    mapping(address => mapping(uint256 => uint256[])) public userIds;
    mapping(address => mapping(uint256 => uint256[])) public userMissions;
    mapping(address => Lolli) public lollipops;
    mapping(address => uint256) public funghiBalance;
    mapping(address => uint256) public feromonBalance;
    mapping(address => uint256) public capacity;
    mapping(address => uint256) public nested;
    mapping(uint256 => uint256[]) public access;

    /// @dev QLWSMP(012345) => counter;
    mapping(uint256 => uint256) counters;
    mapping(uint256 => Q) public q;
    mapping(uint256 => L) public l;
    mapping(uint256 => W) public w;
    mapping(uint256 => S) public s;
    mapping(uint256 => M) public m;
    mapping(uint256 => P) public p;

    uint256[3] public fert;

    // modifiers
    modifier xp(uint256 _amount) {
        feromonBalance[msg.sender] += _amount;
        _;
    }

    modifier checkAccess(uint256 _type, uint256 _targetType) {
        bool passed;
        for (uint256 i; i < access[_type].length; i++) {
            if (access[_type][i] == _targetType) {
                passed = true;
            }
        }
        require(passed);
        _;
    }

    // initialization
    function initialize() external initializer {
        tournament = ITournament(msg.sender);
        schedule.workerFarm = 1;
        schedule.workerBuild = 5;
        schedule.soldierRaid = 3;
        schedule.zombieHarvest = 5;
        schedule.zombieGuard = 1;
        schedule.incubation = 1;
        schedule.queenPeriod = 1;
        schedule.lollipopDuration = 1;
        schedule.zombification = 10;
        nonce = 42;
        fert = [5, 9, 12];
    }

    function setAccess(uint256 _moduleId, uint256[] calldata addrs)
        public
        onlyOwner
    {
        access[_moduleId] = addrs;
    }

    // generalized fxns
    function getUserSpeed(address _user) public view returns (uint256 speed) {
        speed = lollipops[_user].timestamp + schedule.lollipopDuration >
            block.timestamp
            ? 2
            : 1;
    }

    function getUserIds(
        address _user,
        uint256 _type,
        bool _available
    ) public view returns (uint256[] memory ids) {
        ids = new uint256[](getLength(_user, _type, true));
        uint256 total = getLength(_user, _type, false);
        uint256 counter;
        if (_available) {
            for (uint256 i; i < total; i++) {
                if (
                    (_type == 1 &&
                        l[userIds[_user][_type][i]].mission.missionFinalized) ||
                    (_type == 2 &&
                        w[userIds[_user][_type][i]].mission.missionFinalized) ||
                    (_type == 3 &&
                        s[userIds[_user][_type][i]].mission.missionFinalized) ||
                    (_type == 4 &&
                        m[userIds[_user][_type][i]].mission.missionFinalized) ||
                    (_type == 5 &&
                        p[userIds[_user][_type][i]].mission.missionFinalized)
                ) {
                    ids[counter] = userIds[msg.sender][_type][counter];
                }
            }
        } else {
            ids = userIds[msg.sender][_type];
        }
    }

    function getLength(
        address _user,
        uint256 _type,
        bool _available
    ) public view returns (uint256 length) {
        length = userIds[_user][_type].length;
        if (_available) {
            for (uint256 i; i < length; i++) {
                if (
                    (_type == 1 &&
                        !l[userIds[_user][_type][i]]
                            .mission
                            .missionFinalized) ||
                    (_type == 2 &&
                        !w[userIds[_user][_type][i]]
                            .mission
                            .missionFinalized) ||
                    (_type == 3 &&
                        !s[userIds[_user][_type][i]]
                            .mission
                            .missionFinalized) ||
                    (_type == 4 &&
                        !m[userIds[_user][_type][i]]
                            .mission
                            .missionFinalized) ||
                    (_type == 5 &&
                        !p[userIds[_user][_type][i]].mission.missionFinalized)
                ) {
                    length--;
                }
            }
        }
    }

    function getUserMissions(address _user, uint256 _type)
        public
        view
        returns (uint256[] memory ids)
    {
        ids = userMissions[_user][_type];
    }

    function getMissionIds(
        address _user,
        uint256 _type,
        uint256 _id
    ) public view returns (uint256[] memory ids) {
        uint256 length;
        for (uint256 i; i < userMissions[_user][_type].length; i++) {
            if (
                (_type == 1 &&
                    l[userMissions[_user][_type][i]].mission.missionId ==
                    _id) ||
                (_type == 2 &&
                    w[userMissions[_user][_type][i]].mission.missionId ==
                    _id) ||
                (_type == 3 &&
                    s[userMissions[_user][_type][i]].mission.missionId ==
                    _id) ||
                (_type == 4 &&
                    m[userMissions[_user][_type][i]].mission.missionId ==
                    _id) ||
                (_type == 5 &&
                    p[userMissions[_user][_type][i]].mission.missionId == _id)
            ) {
                length++;
            }
        }
        ids = new uint256[](length);
        for (uint256 i; i < userMissions[_user][_type].length; i++) {
            if (
                (_type == 1 &&
                    l[userMissions[_user][_type][i]].mission.missionId ==
                    _id) ||
                (_type == 2 &&
                    w[userMissions[_user][_type][i]].mission.missionId ==
                    _id) ||
                (_type == 3 &&
                    s[userMissions[_user][_type][i]].mission.missionId ==
                    _id) ||
                (_type == 4 &&
                    m[userMissions[_user][_type][i]].mission.missionId ==
                    _id) ||
                (_type == 5 &&
                    p[userMissions[_user][_type][i]].mission.missionId == _id)
            ) {
                ids[i] = userMissions[_user][_type][i];
            }
        }
    }

    function openPack(address _user, uint256 _pack) public {
        require(msg.sender == address(tournament), "Only tournament can call.");
        if (_pack == 0) {
            print(_user, 0, 1, 20);
        } else if (_pack == 1) {
            print(_user, 0, 1, 15);
            print(_user, 0, 5, 1);
        } else if (_pack == 2) {
            print(_user, 0, 1, 10);
            print(_user, 0, 0, 1);
        }
    }

    function kill(
        address _user,
        uint256 _type,
        uint256 _targetType,
        uint256 _id
    ) public checkAccess(_type, _targetType) {
        userIds[_user][_type][_id] = userIds[_user][_type][
            userIds[_user][_type].length - 1
        ];
        userIds[_user][_type].pop();
        nested[_user]--;
    }

    function print(
        address _user,
        uint256 _type,
        uint256 _targetType,
        uint256 _amount
    ) public checkAccess(_type, _targetType) {
        require(
            _amount <= capacity[msg.sender] - nested[msg.sender],
            "You don't have enough nest capacity."
        );
        for (uint256 i; i < _amount; i++) {
            userIds[_user][_targetType].push(counters[_targetType]);
            counters[_targetType]++;
            nested[_user]++;
        }
    }

    // module ids
    // 0..5 Q..P

    function addToMission(
        uint256 _type,
        uint256 _targetType,
        uint256 _missionType,
        uint256 _id,
        uint256 _missionId
    ) public checkAccess(_type, _targetType) {
        Mission memory mission = Mission(
            _missionId,
            _missionType,
            block.timestamp,
            false
        );
        if (_type == 1) {
            l[_id].mission = mission;
        } else if (_type == 2) {
            w[_id].mission = mission;
        } else if (_type == 3) {
            s[_id].mission = mission;
        } else if (_type == 4) {
            m[_id].mission = mission;
        } else if (_type == 5) {
            p[_id].mission = mission;
        }
    }

    function earnXp(
        uint256 _type,
        uint256 _targetType,
        address _user,
        uint256 _amount
    ) public checkAccess(_type, _targetType) {
        feromonBalance[_user] += _amount;
    }

    function earnFunghi(
        uint256 _type,
        uint256 _targetType,
        address _user,
        uint256 _amount
    ) public checkAccess(_type, _targetType) {
        funghiBalance[_user] += _amount;
    }

    function increaseCapacity(
        uint256 _type,
        uint256 _targetType,
        address _user,
        uint256 _amount
    ) public checkAccess(_type, _targetType) {
        capacity[_user] += _amount;
    }

    function createMission(
        address _user,
        uint256 _type,
        uint256 _targetType
    ) public checkAccess(_type, _targetType) returns (uint256 highest) {
        highest = Quicksort.quick(userMissions[_user][_type]) + 1;
        userMissions[_user][_type].push(highest);
    }

    function decreaseHP(
        uint256 _type,
        uint256 _targetType,
        uint256 _id
    ) public checkAccess(_type, _targetType) {
        if (_targetType == 2) {
            w[_id].hp--;
        } else if (_targetType == 3) {
            s[_id].hp--;
        }
    }

    // // larva fxns
    // function incubate(uint256 _amount, uint256 _feedAmount) public xp(_amount) {
    //     uint256[] memory larvae = getUserIds(msg.sender, 1, true);
    //     require(_amount <= larvae.length, "Not enough larvae");
    //     require(
    //         funghiBalance[msg.sender] > _feedAmount * tariff.larvaPortion,
    //         "You don't have enough $Funghi"
    //     );
    //     uint256 highest = addMission(msg.sender, 1);
    //     for (uint256 i; i < _amount; i++) {
    //         l[larvae[i]].mission.missionId = highest + 1;
    //         l[larvae[i]].mission.missionType = _feedAmount > 0 ? 1 : 0;
    //         l[larvae[i]].mission.missionTimestamp = block.timestamp;
    //         _feedAmount = _feedAmount > 0 ? _feedAmount - 1 : 0;
    //     }
    //     funghiBalance[msg.sender] -= tariff.larvaPortion * _feedAmount;
    //     feromonBalance[msg.sender] += _amount;
    // }

    // function hatch(uint256 _id) public {
    //     uint256[] memory ids = getMissionIds(msg.sender, 1, _id);
    //     require(
    //         ids.length <= capacity[msg.sender] - nested[msg.sender],
    //         "You don't have enough nest capacity."
    //     );
    //     for (uint256 i = 0; i < ids.length; i++) {
    //         _hatch(msg.sender, ids[i]);
    //     }
    // }

    // function isBoosted(
    //     address _user,
    //     uint256 _type,
    //     uint256 _id
    // ) public view returns (bool) {
    //     if (
    //         _type == 1 &&
    //         l[_id].mission.missionTimestamp > lollipops[_user].timestamp &&
    //         l[_id].mission.missionTimestamp <=
    //         (lollipops[_user].timestamp + schedule.lollipopDuration)
    //     ) {
    //         return true;
    //     }
    //     return false;
    // }

    // function _hatch(address _user, uint256 _id) private {
    //     uint16 modulo = l[_id].mission.missionType == 1 ? 50 : 100;
    //     uint8 speed = _isBoosted(_user, 1, _id) ? 2 : 1;
    //     require(l[_id].mission.missionTimestamp > 0);
    //     require(
    //         block.timestamp - l[_id].mission.missionTimestamp >
    //             schedule.incubation / speed
    //     );
    //     nonce =
    //         uint256(keccak256(abi.encodePacked(msg.sender, nonce))) %
    //         modulo;
    //     require(nested[_user] < capacity[_user]);
    //     if (nonce < 3) {
    //         p[counters[5]] = P(Mission(0, 0, 0, false), true);
    //         _print(_user, 5, 1);
    //     } else if (nonce >= 3 && nonce < 18) {
    //         m[counters[4]] = M(Mission(0, 0, 0, false), true);
    //         _print(_user, 4, 1);
    //     } else if (nonce >= 18 && nonce < 33) {
    //         s[counters[3]] = S(4, Mission(0, 0, 0, false), 0, true);
    //         _print(_user, 3, 1);
    //     } else {
    //         w[counters[2]] = W(5, Mission(0, 0, 0, false), true);
    //         _print(_user, 2, 1);
    //     }
    //     _kill(_user, 1, _id);
    //     nested[_user]++;
    // }

    // // queen fxns
    // function claimAllEggs() public {
    //     for (uint256 i; i < userIds[msg.sender][0].length; i++) {
    //         claimEggs(userIds[msg.sender][0][i]);
    //     }
    // }

    // function claimEggs(uint256 _id) public {
    //     uint256 deserved = eggsLaid(_id) - q[_id].eggs;
    //     if (deserved > 0) {
    //         q[_id].eggs += deserved;
    //         _print(msg.sender, 1, deserved);
    //         feromonBalance[msg.sender] += deserved;
    //     }
    // }

    // function eggsLaid(uint256 _id) public view returns (uint256 eggs) {
    //     uint256 epochs = (block.timestamp - q[_id].timestamp) /
    //         tournament.epochDuration();
    //     uint256 initEggs = fert[q[_id].level - 1];
    //     if (epochs > initEggs) {
    //         epochs = initEggs;
    //     }
    //     for (uint256 i = 0; i < epochs; i++) {
    //         eggs += initEggs;
    //         initEggs -= 1;
    //     }
    // }

    // function feedQueen(uint256 _id) public {
    //     claimEggs(_id);
    //     uint256 epochs = (block.timestamp - q[_id].timestamp) /
    //         tournament.epochDuration();
    //     uint256 amount = epochs * tariff.queenPortion;
    //     q[_id].timestamp = block.timestamp;
    //     q[_id].eggs = 0;
    //     funghiBalance[msg.sender] -= amount;
    //     feromonBalance[msg.sender] += epochs;
    // }

    // function queenUpgrade(uint256 _id) public {
    //     uint256 amount = q[_id].level == 1
    //         ? tariff.queenUpgrade
    //         : tariff.queenUpgrade * 3;
    //     require(feromonBalance[msg.sender] >= amount, "Not enough feromon.");
    //     require(q[_id].level < 3);
    //     claimEggs(_id);
    //     feedQueen(_id);
    //     feromonBalance[msg.sender] -= amount;
    //     q[_id].level += 1;
    // }

    // function getQueenEnergy(uint256 _id) public view returns (uint256 energy) {
    //     uint256 max = tournament.epochDuration() * fert[q[_id].level - 1];
    //     uint256 diff = block.timestamp - q[_id].timestamp;
    //     if (diff > max) {
    //         energy = 0;
    //     } else {
    //         energy = ((max - diff) * 100) / max;
    //     }
    // }
}
