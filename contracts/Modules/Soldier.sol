//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Interfaces/IMicroColonies.sol";
import "../Interfaces/ITournament.sol";
import "../Helpers/Quick.sol";
import "hardhat/console.sol";

contract Soldier is Initializable {
    IMicroColonies private micro;
    ITournament private tournament;
    uint256 private nonce;

    function initialize(address _micro) external initializer {
        micro = IMicroColonies(_micro);
        tournament = ITournament(msg.sender);
        nonce = 42;
    }

    // integrate infection
    function scout(uint256 _amount) public isSafe(true) {
        uint256[] memory ids = micro.getUserIds(msg.sender, 3, true);
        require(_amount <= ids.length, "Not enough soldiers.");
        uint256 missionId = micro.createMission(msg.sender, 3, 3);
        for (uint256 i; i < _amount; i++) {
            micro.addToMission(msg.sender, 3, 3, 0, ids[i], missionId);
        }
        micro.earnXp(3, 3, msg.sender, _amount);
    }

    function otherParticipants(address _user)
        public
        view
        returns (address[] memory participants)
    {
        uint256 counter;
        address[] memory allParticipants = micro.getParticipants();
        participants = new address[](allParticipants.length - 1);
        for (uint256 i = 0; i < allParticipants.length; i++) {
            if (allParticipants[i] != _user) {
                participants[counter] = allParticipants[i];
                counter++;
            }
        }
    }

    modifier isSafe(bool _deploy) {
        uint256 now_ = block.timestamp;
        if (micro.inhibitions(3).deploy == _deploy) {
            require(now_ > micro.inhibitions(3).end);
        }
        _;
    }

    function reveal(uint256 _id) public view returns (address target) {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 3, _id);
        uint256 speed = isBoosted(msg.sender, _id) ? 2 : 1;
        require(
            micro.s(ids[0]).mission.missionTimestamp +
                micro.schedule().soldierRaid /
                speed <
                block.timestamp,
            "Mission is not over yet."
        );
        address[] memory participants = otherParticipants(msg.sender);
        uint256 prob = uint256(keccak256(abi.encodePacked(msg.sender, _id))) %
            participants.length;
        target = participants[prob];
    }

    function retreat(uint256 _id) public isSafe(false) {
        micro.finalizeMission(msg.sender, 3, 3, _id);
    }

    function getIncubating(address _user)
        public
        view
        returns (uint256[] memory incubatingLarvae)
    {
        uint256[] memory larvae = micro.getUserIds(_user, 1, false);
        uint256 incubating;
        for (uint256 i; i < larvae.length; i++) {
            if (
                (block.timestamp >
                    micro.l(larvae[i]).mission.missionTimestamp) &&
                (!micro.l(larvae[i]).mission.missionFinalized) &&
                (micro.l(larvae[i]).mission.missionTimestamp > 0)
            ) {
                incubating++;
            }
        }
        uint256 counter;
        incubatingLarvae = new uint256[](incubating);
        for (uint256 i; i < larvae.length; i++) {
            if (
                (block.timestamp >
                    micro.l(larvae[i]).mission.missionTimestamp) &&
                (!micro.l(larvae[i]).mission.missionFinalized) &&
                (micro.l(larvae[i]).mission.missionTimestamp > 0)
            ) {
                incubatingLarvae[counter] = larvae[i];
                counter++;
            }
        }
    }

    function attack(uint256 _id) public isSafe(false) {
        uint256[] memory soldiers = micro.getMissionIds(msg.sender, 3, _id);
        uint256[] memory targetSoldiers = micro.getUserIds(
            reveal(_id),
            3,
            true
        );
        uint256[] memory targetLarvae = getIncubating(reveal(_id));
        require(targetLarvae.length > 0, "Target has no larvae.");
        uint256 reward = battle(
            soldiers.length,
            targetSoldiers.length,
            targetLarvae.length
        );
        if (reward == 0) {
            return ();
        }
        for (uint256 i; i < reward; i++) {
            micro.kill(reveal(_id), 3, 1, targetLarvae[i]);
        }
        micro.print(msg.sender, 3, 1, reward);
        micro.finalizeMission(msg.sender, 3, 3, _id);
    }

    // integrate zombies
    function battle(
        uint256 attackerSoldierCount,
        uint256 targetSoldierCount,
        uint256 targetLarvaeCount
    ) public returns (uint256 reward) {
        uint256 rollCount = attackerSoldierCount > targetSoldierCount
            ? targetSoldierCount
            : attackerSoldierCount;
        uint256[] memory targetRolls = new uint256[](rollCount);
        uint256[] memory attackerRolls = new uint256[](rollCount);
        for (uint256 j; j < rollCount; j++) {
            nonce = uint256(keccak256(abi.encodePacked(msg.sender, nonce)));
            targetRolls[j] = nonce % 100;
            nonce = uint256(keccak256(abi.encodePacked(msg.sender, nonce)));
            attackerRolls[j] = nonce % 100;
        }
        targetRolls = Quicksort.getDescending(targetRolls);
        attackerRolls = Quicksort.getDescending(attackerRolls);
        uint256 attackerWins = 0;
        uint256 defenderWins = 0;
        for (uint256 i = 0; i < rollCount; i++) {
            // do rolls here
            if (attackerRolls[i] > targetRolls[i]) {
                attackerWins++;
            } else {
                defenderWins++;
            }
        }
        reward += attackerWins;
        if (attackerSoldierCount > targetSoldierCount) {
            uint256 remainingAttacks = attackerSoldierCount -
                targetSoldierCount;
            for (uint256 i = 0; i < remainingAttacks; i++) {
                nonce = uint256(keccak256(abi.encodePacked(msg.sender, nonce)));
                if (nonce % 100 < 100) {
                    // 80 in production
                    reward++;
                }
            }
        }
        if (targetLarvaeCount < reward) {
            reward = targetLarvaeCount;
        }
    }

    function isBoosted(address _user, uint256 _id) public view returns (bool) {
        uint256 id = micro.getMissionIds(_user, 3, _id)[0];
        return
            (micro.s(id).mission.missionTimestamp >
                micro.lollipops(_user).timestamp &&
                micro.s(id).mission.missionTimestamp <=
                (micro.lollipops(_user).timestamp +
                    micro.schedule().lollipopDuration))
                ? true
                : false;
    }

    function harvest(uint256 _amount) public {
        uint256[] memory ids = micro.getUserIds(msg.sender, 3, true);
        require(_amount <= ids.length, "Not enough soldiers.");
        uint256 missionId = micro.createMission(msg.sender, 3, 3);
        micro.earnXp(3, 3, msg.sender, _amount);
        for (uint256 i; i < ids.length; i++) {
            if (_amount > 0 && micro.s(ids[i]).hp == 0) {
                micro.addToMission(msg.sender, 3, 3, 1, ids[i], missionId);
                _amount--;
            }
        }
    }

    function claimHarvested(uint256 _id) public {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 3, _id);
        uint8 speed = isBoosted(msg.sender, _id) ? 2 : 1;
        require(micro.s(_id).mission.missionTimestamp != 0);
        require(
            micro.s(_id).mission.missionTimestamp +
                micro.schedule().zombieHarvest /
                speed <
                block.timestamp
        );
        require(!micro.w(_id).mission.missionFinalized);
        for (uint256 i; i < ids.length; i++) {
            micro.kill(msg.sender, 3, 3, ids[i]);
        }
        micro.earnFunghi(
            3,
            3,
            msg.sender,
            ids.length * micro.tariff().zombieHarvest
        );
        micro.finalizeMission(msg.sender, 3, 3, _id);
    }

    function defend(uint256 _amount) public {
        uint256[] memory ids = micro.getUserIds(msg.sender, 3, true);
        require(_amount <= ids.length, "Not enough soldiers.");
        uint256 missionId = micro.createMission(msg.sender, 3, 3);
        micro.earnXp(3, 3, msg.sender, _amount);
        for (uint256 i; i < ids.length; i++) {
            if (_amount > 0 && micro.s(ids[i]).hp == 0) {
                micro.addToMission(msg.sender, 3, 3, 2, ids[i], missionId);
                _amount--;
            }
        }
    }

    function defenders() public view returns (uint256[] memory defendings) {
        uint256[] memory ids = micro.getUserIds(msg.sender, 3, true);
        uint256 defending;
        for (uint256 i; i < ids.length; i++) {
            if (
                micro.s(ids[i]).mission.missionType == 2 &&
                micro.s(ids[i]).mission.missionTimestamp +
                    micro.schedule().zombieGuard >
                block.timestamp
            ) {
                defending++;
            }
        }
        defendings = new uint256[](defending);
        uint256 counter;
        for (uint256 i; i < ids.length; i++) {
            if (
                micro.s(ids[i]).mission.missionType == 2 &&
                micro.s(ids[i]).mission.missionTimestamp +
                    micro.schedule().zombieGuard >
                block.timestamp
            ) {
                defendings[counter] = ids[i];
                counter++;
            }
        }
    }
}
