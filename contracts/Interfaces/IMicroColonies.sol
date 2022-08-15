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
}

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

interface IMicroColonies {
    function openPack(address _user, uint256 _pack) external;

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

    function feromonBalance(address) external view returns (uint256 balance);

    function createMission(
        address _user,
        uint256 _type,
        uint256 _targetType
    ) external returns (uint256 missionId);

    function addToMission(
        uint256 _type,
        uint256 _targetType,
        uint256 _missionType,
        uint256 _id,
        uint256 _missionId
    ) external;

    function earnXp(
        uint256 _type,
        uint256 _targetType,
        address _user,
        uint256 _amount
    ) external;

    function earnFunghi(
        uint256 _type,
        uint256 _targetType,
        address _user,
        uint256 _amount
    ) external;

    function decreaseHP(
        uint256 _type,
        uint256 _targetType,
        uint256 _id
    ) external;

    function isBoosted(
        address _user,
        uint256 _type,
        uint256 _id
    ) external view returns (bool);

    function kill(
        address _user,
        uint256 _type,
        uint256 _targetType,
        uint256 _id
    ) external;

    function print(
        address _user,
        uint256 _type,
        uint256 _targetType,
        uint256 _amount
    ) external;

    function increaseCapacity(
        uint256 _type,
        uint256 _targetType,
        address _user,
        uint256 _amount
    ) external;

    function q(uint256 _id) external view returns (Q calldata q);

    function l(uint256 _id) external view returns (L calldata l);

    function w(uint256 _id) external view returns (W calldata w);

    function s(uint256 _id) external view returns (S calldata s);

    function m(uint256 _id) external view returns (M calldata m);

    function p(uint256 _id) external view returns (P calldata p);
}
