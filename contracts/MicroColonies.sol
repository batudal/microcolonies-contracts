//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Interfaces/ITournament.sol";

contract MicroColonies is Initializable, OwnableUpgradeable {
    Schedule public schedule;
    Tariff public tariff;
    ITournament public tournament;
    uint256 private nonce;
    address[] public participants;

    struct Schedule {
        uint256 epoch;
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
        uint256 mating;
    }
    struct Tariff {
        uint256 larvaPortion;
        uint256 queenPortion;
        uint256 queenUpgrade;
        uint256 conversion;
        uint256 zombieHarvest;
        uint256 farmReward;
        uint256 buildReward;
        uint256 soldierHeal;
    }
    struct Q {
        uint256 level;
        uint256 eggs;
        uint256 timestamp;
        // Mission mission; // IMPLEMENT!!
    }
    struct L {
        Mission mission; // missionType (0-unfed, 1-fed)
    }
    struct W {
        uint8 hp;
        Mission mission; // missionType (0-farm, 1-build, 2-conversion)
    }
    struct S {
        uint256 hp; // 2 full 1 infected 0 dead
        Mission mission; // missionType (0-scout)
        uint256 damageTimestamp;
    }
    struct Z {
        Mission mission; // missionType (0-harvest, 1-defend)
    }
    struct M {
        Mission mission;
    }
    struct P {
        Mission mission;
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

    enum MissionState {
        NULL,
        INITIALIZED,
        COMPLETED
    }

    /// battle (50) 50 soldier -> WRITE +50

    /// @dev user => QLWSMPZ => ids
    mapping(address => mapping(uint256 => uint256[])) public userIds;
    mapping(address => mapping(uint256 => uint256[])) public userMissions; // convert to Mission[]
    mapping(address => mapping(uint256 => mapping(uint256 => uint256[])))
        public missionIds;
    mapping(address => mapping(uint256 => mapping(uint256 => MissionState)))
        public missionStates;
    mapping(address => Lolli) public lollipops;
    mapping(address => uint256) public funghiBalance;
    mapping(address => uint256) public feromonBalance;
    mapping(address => uint256) public capacity;
    mapping(address => uint256) public nested;
    mapping(address => uint256[]) public access;

    /// @dev QLWSMPZ(0123456) => counter;
    mapping(uint256 => uint256) counters;
    mapping(uint256 => Q) public q;
    mapping(uint256 => L) public l;
    mapping(uint256 => W) public w;
    mapping(uint256 => S) public s;
    mapping(uint256 => Z) public z;
    mapping(uint256 => M) public m;
    mapping(uint256 => P) public p;

    // modifier
    modifier xp(uint256 _amount) {
        feromonBalance[msg.sender] += _amount;
        _;
    }

    modifier checkAccess(address _module, uint256 _target) {
        _checkAccess(_module, _target);
        _;
    }

    function _checkAccess(address _module, uint256 _target) internal view {
        if (_module != address(tournament)) {
            bool passed;
            for (uint256 i; i < access[_module].length; i++) {
                if (access[_module][i] == _target) {
                    passed = true;
                }
            }
            require(passed);
        }
    }

    modifier checkState() {
        _checkState();
        _;
    }

    function _checkState() internal view {
        require(
            block.timestamp <
                tournament.startDate() + tournament.tournamentDuration(),
            "Tournament is over."
        );
    }

    function initialize(uint256 _epoch) external initializer {
        tournament = ITournament(msg.sender);
        schedule.epoch = _epoch;
        schedule.workerFarm = 1;
        schedule.workerBuild = 5;
        schedule.conversion = 1;
        schedule.soldierRaid = 3;
        schedule.zombification = 5;
        schedule.zombieHarvest = 5;
        schedule.zombieGuard = 1;
        schedule.incubation = 1;
        schedule.queenPeriod = 1;
        schedule.lollipopDuration = 1;
        schedule.mating = 4;
        tariff.larvaPortion = 400;
        tariff.queenPortion = 240;
        tariff.queenUpgrade = 1000;
        tariff.conversion = 10; /// production: 100
        tariff.zombieHarvest = 400;
        tariff.farmReward = 80;
        tariff.buildReward = 5;
        tariff.soldierHeal = 80;
        nonce = 52; /// production: block.timestamp
        __Ownable_init();
    }

    function setAccess(address _module, uint256[] calldata _targets)
        public
        onlyOwner
    {
        access[_module] = _targets;
    }

    function getParticipants()
        public
        view
        returns (address[] memory participants_)
    {
        participants_ = participants;
    }

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
                        (l[userIds[_user][_type][i]].mission.missionFinalized ||
                            l[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 2 &&
                        (w[userIds[_user][_type][i]].mission.missionFinalized ||
                            w[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 3 &&
                        (s[userIds[_user][_type][i]].mission.missionFinalized ||
                            s[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 4 &&
                        (m[userIds[_user][_type][i]].mission.missionFinalized ||
                            m[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 6 &&
                        (z[userIds[_user][_type][i]].mission.missionFinalized ||
                            z[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 5 &&
                        (p[userIds[_user][_type][i]].mission.missionFinalized ||
                            p[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0))
                ) {
                    ids[counter] = userIds[_user][_type][i];
                    counter++;
                }
            }
        } else {
            ids = userIds[_user][_type];
        }
    }

    function getMissionState(
        address _user,
        uint256 _type,
        uint256 _id
    ) public view returns (MissionState state) {
        state = missionStates[_user][_type][_id];
    }

    function getLength(
        address _user,
        uint256 _type,
        bool _available
    ) public view returns (uint256 length) {
        if (_available) {
            for (uint256 i; i < userIds[_user][_type].length; i++) {
                if (
                    (_type == 0) ||
                    (_type == 1 &&
                        (l[userIds[_user][_type][i]].mission.missionFinalized ||
                            l[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 2 &&
                        (w[userIds[_user][_type][i]].mission.missionFinalized ||
                            w[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 3 &&
                        (s[userIds[_user][_type][i]].mission.missionFinalized ||
                            s[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 4 &&
                        (m[userIds[_user][_type][i]].mission.missionFinalized ||
                            m[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 6 &&
                        (z[userIds[_user][_type][i]].mission.missionFinalized ||
                            z[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0)) ||
                    (_type == 5 &&
                        (p[userIds[_user][_type][i]].mission.missionFinalized ||
                            p[userIds[_user][_type][i]]
                                .mission
                                .missionTimestamp ==
                            0))
                ) {
                    length++;
                }
            }
        } else {
            length = userIds[_user][_type].length;
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
    ) public view returns (uint256[] memory) {
        return missionIds[_user][_type][_id];
    }

    function isBoosted(
        address _user,
        uint256 _type,
        uint256 _id
    ) public view returns (bool) {
        if (
            _type == 1 &&
            l[_id].mission.missionTimestamp > lollipops[_user].timestamp &&
            l[_id].mission.missionTimestamp <=
            (lollipops[_user].timestamp + schedule.lollipopDuration)
        ) {
            return true;
        }
        return false;
    }

    function setNonce(uint256 _target)
        public
        checkAccess(msg.sender, _target)
        checkState
        returns (uint256 nextNonce)
    {
        nonce = uint256(keccak256(abi.encodePacked(msg.sender, nonce)));
        nextNonce = nonce;
    }

    function openPack(address _user) public checkState {
        require(msg.sender == address(tournament), "Only tournament can call.");
        increaseCapacity(0, _user, 20);
        print(_user, 1, 19);
        print(_user, 0, 1);
        participants.push(_user);
        funghiBalance[_user] = 100000; // remove at production!
        feromonBalance[_user] = 100000; // remove at production!
    }

    function useLollipop() public checkState {
        require(!lollipops[msg.sender].used);
        lollipops[msg.sender].used = true;
        lollipops[msg.sender].timestamp = block.timestamp;
    }

    function findIndex(
        address _user,
        uint256 _type,
        uint256 _id
    ) private view returns (uint256 index) {
        for (uint256 i; i < userIds[_user][_type].length; i++) {
            if (userIds[_user][_type][i] == _id) {
                index = i;
            }
        }
    }

    function kill(
        address _user,
        uint256 _target,
        uint256 _id
    ) public checkAccess(msg.sender, _target) checkState {
        uint256 index = findIndex(_user, _target, _id);
        if (userIds[_user][_target].length > 0) {
            userIds[_user][_target][index] = userIds[_user][_target][
                userIds[_user][_target].length - 1
            ];
        }
        userIds[_user][_target].pop();
        if (_target != 1) {
            nested[_user]--;
        }
    }

    function print(
        address _user,
        uint256 _target,
        uint256 _amount
    ) public checkAccess(msg.sender, _target) checkState {
        if (_target != 1) {
            require(
                _amount <= (capacity[_user] - nested[_user]),
                "You don't have enough nest capacity."
            );
        }
        for (uint256 i; i < _amount; i++) {
            if (_target == 0) {
                q[counters[0]] = Q(1, 0, block.timestamp);
            } else if (_target == 1) {
                l[counters[1]] = L(Mission(0, 0, 0, false));
            } else if (_target == 5) {
                p[counters[5]] = P(Mission(0, 0, 0, false));
            } else if (_target == 4) {
                m[counters[4]] = M(Mission(0, 0, 0, false));
            } else if (_target == 3) {
                s[counters[3]] = S(2, Mission(0, 0, 0, false), 0);
            } else if (_target == 2) {
                w[counters[2]] = W(5, Mission(0, 0, 0, false));
            } else if (_target == 6) {
                z[counters[6]] = Z(Mission(0, 0, 0, false));
            }
            userIds[_user][_target].push(counters[_target]);
            counters[_target]++;
            if (_target != 1) {
                nested[_user]++;
            }
        }
    }

    function createMission(address _user, uint256 _target)
        public
        checkAccess(msg.sender, _target)
        checkState
        returns (uint256 highest)
    {
        if (userMissions[_user][_target].length > 0) {
            highest =
                userMissions[_user][_target][
                    userMissions[_user][_target].length - 1
                ] +
                1;
        } else {
            highest = 1;
        }
        missionStates[_user][_target][highest] = MissionState(1);
        userMissions[_user][_target].push(highest);
    }

    function addToMission(
        address _user,
        uint256 _target,
        uint256 _missionType,
        uint256 _id,
        uint256 _missionId
    ) public checkAccess(msg.sender, _target) checkState {
        Mission memory mission = Mission(
            _missionId,
            _missionType,
            block.timestamp,
            false
        );
        if (_target == 1) {
            l[_id].mission = mission;
        } else if (_target == 2) {
            w[_id].mission = mission;
        } else if (_target == 3) {
            s[_id].mission = mission;
        } else if (_target == 4) {
            m[_id].mission = mission;
        } else if (_target == 5) {
            p[_id].mission = mission;
        } else if (_target == 6) {
            z[_id].mission = mission;
        }
        missionIds[_user][_target][_missionId].push(_id);
    }

    function finalizeMission(
        address _user,
        uint256 _target,
        uint256 _id
    ) public checkAccess(msg.sender, _target) checkState {
        uint256[] memory ids = getMissionIds(_user, _target, _id);
        for (uint256 i; i < ids.length; i++) {
            if (_target == 1) {
                l[ids[i]].mission.missionFinalized = true;
            } else if (_target == 2) {
                w[ids[i]].mission.missionFinalized = true;
            } else if (_target == 3) {
                s[ids[i]].mission.missionFinalized = true;
            } else if (_target == 4) {
                m[ids[i]].mission.missionFinalized = true;
            } else if (_target == 5) {
                p[ids[i]].mission.missionFinalized = true;
            } else if (_target == 6) {
                z[ids[i]].mission.missionFinalized = true;
            }
        }
        missionStates[_user][_target][_id] = MissionState(2);
    }

    function earnXp(
        uint256 _target,
        address _user,
        uint256 _amount
    ) public checkAccess(msg.sender, _target) checkState {
        feromonBalance[_user] += _amount;
    }

    function earnFunghi(
        uint256 _target,
        address _user,
        uint256 _amount
    ) public checkAccess(msg.sender, _target) checkState {
        funghiBalance[_user] += _amount;
    }

    function spendFunghi(
        uint256 _target,
        address _user,
        uint256 _amount
    ) public checkAccess(msg.sender, _target) {
        funghiBalance[_user] -= _amount;
    }

    function spendFeromon(
        uint256 _target,
        address _user,
        uint256 _amount
    ) public checkAccess(msg.sender, _target) {
        feromonBalance[_user] -= _amount;
    }

    function resetQueen(uint256 _target, uint256 _id)
        public
        checkAccess(msg.sender, _target)
    {
        q[_id].timestamp = block.timestamp;
        q[_id].eggs = 0;
    }

    function increaseCapacity(
        uint256 _target,
        address _user,
        uint256 _amount
    ) public checkAccess(msg.sender, _target) {
        capacity[_user] += _amount;
    }

    function decreaseHP(uint256 _target, uint256 _id)
        public
        checkAccess(msg.sender, _target)
    {
        if (_target == 2) {
            require(w[_id].hp > 0, "Worker is dead already.");
            w[_id].hp--;
        } else if (_target == 3) {
            require(s[_id].hp > 0, "Soldier is dead already.");
            s[_id].hp--;
        }
    }

    function addEggs(
        uint256 _target,
        uint256 _id,
        uint256 _amount
    ) public checkAccess(msg.sender, _target) {
        q[_id].eggs += _amount;
    }

    function queenLevelup(uint256 _id, uint256 _target)
        public
        checkAccess(msg.sender, _target)
    {
        q[_id].level++;
    }

    function healSoldier(uint256 _target, uint256 _id)
        public
        checkAccess(msg.sender, _target)
    {
        s[_id].hp == 2;
        s[_id].damageTimestamp = 0;
    }
}
