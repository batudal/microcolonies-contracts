//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../Interfaces/IMicroColonies.sol";
import "../../Interfaces/ITournament.sol";
import "../../Helpers/Quick.sol";

contract Soldier is Initializable {
    IMicroColonies private micro;
    ITournament private tournament;
    uint256 private nonce;

    function initialize(address _micro) external initializer {
        micro = IMicroColonies(_micro);
        tournament = ITournament(msg.sender);
        nonce = 42;
    }

    function scout(uint256 _amount) public {
        uint256[] memory ids = micro.getUserIds(msg.sender, 3, true);
        require(_amount <= ids.length, "Not enough soldiers.");
        uint256 missionId = micro.createMission(msg.sender, 3, 3);
        for (uint256 i; i < _amount; i++) {
            micro.addToMission(3, 3, 0, ids[i], missionId);
        }
        micro.earnXp(3, 3, msg.sender, _amount);
    }

    function otherParticipants(address _user)
        public
        view
        returns (address[] memory participants)
    {
        uint256 counter;
        participants = new address[](micro.participants().length - 1);
        for (uint256 i = 0; i < micro.participants().length; i++) {
            if (micro.participants()[i] != _user) {
                participants[counter] = micro.participants()[i];
                counter++;
            }
        }
    }

    function reveal(uint256 _id) public view returns (address target) {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 2, _id);
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

    function retreat(uint256 _id) public {
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

    function attack(uint256 _id) public {
        uint256[] memory soldiers = micro.getMissionIds(msg.sender, 3, _id);
        uint256[] memory targetSoldiers = micro.getUserIds(
            reveal(_id),
            3,
            true
        );
        uint256[] memory targetLarvae = getIncubating(reveal(_id));

        (uint256 prize, uint256 bonus) = battle(
            soldiers.length,
            targetSoldiers.length,
            targetLarvae.length
        );
        if (prize == 0 && bonus == 0) {
            return ();
        }
        for (uint256 i; i < prize + bonus; i++) {
            micro.kill(reveal(_id), 3, 1, targetLarvae[i]);
        }
        micro.finalizeMission(msg.sender, 3, 3, _id);
    }

    function battle(
        uint256 attackerSoldierCount,
        uint256 targetSoldierCount,
        uint256 targetLarvaeCount
    ) public returns (uint256 prize, uint256 bonus) {
        uint256 rollCount = attackerSoldierCount > targetLarvaeCount
            ? targetLarvaeCount
            : attackerSoldierCount;
        uint256[] memory targetRolls = new uint256[](rollCount);
        uint256[] memory attackerRolls = new uint256[](rollCount);
        targetRolls = Quicksort.getDescending(targetRolls);
        attackerRolls = Quicksort.getDescending(attackerRolls);
        uint256 attackerWins = 0;
        uint256 defenderWins = 0;
        for (uint256 i = 0; i < rollCount; i++) {
            if (attackerRolls[i] > targetRolls[i]) {
                attackerWins++;
            } else {
                defenderWins++;
            }
        }
        if (attackerWins > defenderWins) {
            prize = attackerWins - defenderWins;
        } else {
            prize = 0;
        }
        if (attackerSoldierCount > targetSoldierCount) {
            uint256 remainingAttacks = attackerSoldierCount -
                targetSoldierCount;
            for (uint256 i = 0; i < remainingAttacks; i++) {
                uint256 chance = uint256(
                    keccak256(abi.encodePacked(msg.sender, nonce))
                ) % 100;
                nonce++;
                if (chance < 80) {
                    bonus++;
                }
            }
        }
    }

    function isBoosted(address _user, uint256 _id) public view returns (bool) {
        return
            (micro.s(_id).mission.missionTimestamp >
                micro.lollipops(_user).timestamp &&
                micro.s(_id).mission.missionTimestamp <=
                (micro.lollipops(_user).timestamp +
                    micro.schedule().lollipopDuration))
                ? true
                : false;
    }
}
