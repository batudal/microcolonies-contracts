//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

struct Q {
    uint256 level;
    uint256 eggs;
    uint256 timestamp;
}
struct L {
    Mission mission; // missionType (0-unfed, 1-fed)
}
struct W {
    uint8 hp;
    Mission mission; // missionType (0-farm, 1-build, 2-conversion)
}
struct S {
    uint256 hp; // 4..2 hp 1 zombie 0 null
    Mission mission; // missionType (0-scout, 1-harvest, 2-defend)
    uint256 damageTimestamp;
}
struct Z {
    Mission mission;
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

struct Inhibition {
    uint256 start;
    uint256 end;
    bool deploy;
}

interface IMicroColonies {
    function openPack(address _user) external;

    function lollipops(address _user)
        external
        view
        returns (Lolli calldata lolli);

    function getUserIds(
        address _user,
        uint256 _type,
        bool _available
    ) external view returns (uint256[] memory ids);

    function getMissionIds(
        address _user,
        uint256 _type,
        uint256 _id
    ) external view returns (uint256[] memory ids);

    function tariff() external view returns (Tariff calldata tariff);

    function schedule() external view returns (Schedule calldata schedule);

    function funghiBalance(address) external view returns (uint256 balance);

    function feromonBalance(address) external view returns (uint256 balance);

    function createMission(address _user, uint256 _target)
        external
        returns (uint256 missionId);

    function addToMission(
        address _user,
        uint256 _target,
        uint256 _missionType,
        uint256 _id,
        uint256 _missionId
    ) external;

    function earnXp(
        uint256 _target,
        address _user,
        uint256 _amount
    ) external;

    function earnFunghi(
        uint256 _target,
        address _user,
        uint256 _amount
    ) external;

    function decreaseHP(uint256 _target, uint256 _id) external;

    function isBoosted(
        address _user,
        uint256 _type,
        uint256 _id
    ) external view returns (bool);

    function kill(
        address _user,
        uint256 _target,
        uint256 _id
    ) external;

    function print(
        address _user,
        uint256 _target,
        uint256 _amount
    ) external;

    function increaseCapacity(
        uint256 _target,
        address _user,
        uint256 _amount
    ) external;

    function decreaseCapacity(
        uint256 _type,
        uint256 _targetType,
        address _user,
        uint256 _amount
    ) external;

    function q(uint256 _id) external view returns (Q calldata q);

    function l(uint256 _id) external view returns (L calldata l);

    function w(uint256 _id) external view returns (W calldata w);

    function s(uint256 _id) external view returns (S calldata s);

    function z(uint256 _id) external view returns (Z calldata z);

    function m(uint256 _id) external view returns (M calldata m);

    function p(uint256 _id) external view returns (P calldata p);

    function addEggs(
        uint256 _target,
        uint256 _id,
        uint256 _amount
    ) external;

    function resetQueen(uint256 _target, uint256 _id) external;

    function spendFunghi(
        uint256 _target,
        address _user,
        uint256 _amount
    ) external;

    function spendFeromon(
        uint256 _target,
        address _user,
        uint256 _amount
    ) external;

    function nonce() external view returns (uint256 nonce);

    function capacity(address _user) external view returns (uint256 capacity);

    function nested(address _user) external view returns (uint256 capacity);

    function setNonce(uint256 _target) external returns (uint256 nextNonce);

    function participants()
        external
        view
        returns (address[] calldata participants);

    function getParticipants()
        external
        view
        returns (address[] memory participants_);

    function finalizeMission(
        address _user,
        uint256 _target,
        uint256 _id
    ) external;

    function getUserMissions(address _user, uint256 _type)
        external
        view
        returns (uint256[] memory ids);

    function matingBoost(address _user, uint256 _target) external;

    function initialize(uint256 _epoch) external;

    function queenLevelup(uint256 _id, uint256 _target) external;

    function healSoldier(uint256 _target, uint256 _id) external;

    function setAccess(address _module, uint256[] calldata _targets) external;
}
