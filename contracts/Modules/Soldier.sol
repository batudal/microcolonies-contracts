//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Interfaces/IMicroColonies.sol";
import "../Interfaces/ITournament.sol";
import "../Helpers/Quick.sol";

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
        address[] memory participants = otherParticipants(msg.sender);
        uint256 prob = uint256(keccak256(abi.encodePacked(msg.sender, _id))) %
            participants.length;
        target = participants[prob];
    }

    function retreat(uint256 _id) public isSafe(false) {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 3, _id);
        uint256 killed;
        for (uint256 i; i < ids.length; i++) {
            if (micro.s(ids[i]).hp > 1) {
                micro.decreaseHP(3, 3, ids[i]);
            } else {
                micro.kill(msg.sender, 3, 3, ids[i]);
                killed++;
            }
        }
        micro.print(msg.sender, 3, 6, killed);
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

    function defenders(address _user)
        public
        view
        returns (uint256[] memory defendings)
    {
        uint256[] memory ids = micro.getUserIds(_user, 3, true);
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
        for (uint256 i; i < ids.length; i++) {
            if (
                micro.s(ids[i]).mission.missionType == 2 &&
                micro.s(ids[i]).mission.missionTimestamp +
                    micro.schedule().zombieGuard >
                block.timestamp
            ) {
                defendings[defending] = ids[i];
                defending--;
            }
        }
    }

    function attack(uint256 _id) public isSafe(false) {
        uint256[] memory soldiers = micro.getMissionIds(msg.sender, 3, _id);
        uint256 speed = isBoosted(msg.sender, _id) ? 2 : 1;
        require(
            micro.s(soldiers[0]).mission.missionTimestamp +
                micro.schedule().soldierRaid /
                speed <
                block.timestamp,
            "Mission is not over yet."
        );
        address target = reveal(_id);
        uint256[] memory targetSoldiers = micro.getUserIds(target, 3, true);
        uint256[] memory targetLarvae = getIncubating(target);
        require(targetLarvae.length > 0, "Target has no larvae.");
        uint256[] memory targetZombies = defenders(target);
        uint256 reward = battle(
            target,
            soldiers,
            targetSoldiers,
            targetLarvae,
            targetZombies
        );
        if (reward == 0) {
            micro.finalizeMission(msg.sender, 3, 3, _id);
        }
        for (uint256 i; i < reward; i++) {
            micro.kill(reveal(_id), 3, 1, targetLarvae[i]);
        }
        micro.print(msg.sender, 3, 1, reward);
        micro.finalizeMission(msg.sender, 3, 3, _id);
    }

    function battle(
        address target,
        uint256[] memory attackerSoldiers,
        uint256[] memory targetSoldiers,
        uint256[] memory targetLarvae,
        uint256[] memory targetZombies
    ) public returns (uint256 reward) {
        uint256 attackerSoldierCount = attackerSoldiers.length;
        uint256 targetZombiesCount = targetZombies.length;
        for (uint256 z; z < targetZombies.length; z++) {
            if (attackerSoldierCount > 0) {
                attackerSoldierCount--;
                micro.kill(target, 3, 6, targetZombies[z]);
            } else {
                return (0);
            }
            targetZombiesCount--;
        }
        uint256 rollCount = attackerSoldierCount > targetSoldiers.length
            ? targetSoldiers.length
            : attackerSoldierCount;
        uint256[] memory targetRolls = new uint256[](rollCount);
        uint256[] memory attackerRolls = new uint256[](rollCount);
        uint256 killed;
        for (uint256 j; j < rollCount; j++) {
            nonce = uint256(keccak256(abi.encodePacked(msg.sender, nonce)));
            targetRolls[j] = nonce % 100;
            nonce = uint256(keccak256(abi.encodePacked(msg.sender, nonce)));
            attackerRolls[j] = nonce % 100;
            if (micro.s(targetSoldiers[j]).hp > 1) {
                micro.decreaseHP(3, 3, targetSoldiers[j]);
            } else {
                micro.kill(msg.sender, 3, 3, targetSoldiers[j]);
                killed++;
            }
        }
        micro.print(target, 3, 6, killed);
        targetRolls = Quicksort.getDescending(targetRolls);
        attackerRolls = Quicksort.getDescending(attackerRolls);
        for (uint256 i = 0; i < rollCount; i++) {
            if (attackerRolls[i] > targetRolls[i]) {
                reward++;
            }
        }
        if (attackerSoldierCount > targetSoldiers.length) {
            uint256 remainingAttacks = attackerSoldierCount -
                targetSoldiers.length;
            for (uint256 i = 0; i < remainingAttacks; i++) {
                nonce = uint256(keccak256(abi.encodePacked(msg.sender, nonce)));
                if (nonce % 100 < 80) {
                    reward++;
                }
            }
        }
        if (targetLarvae.length < reward) {
            reward = targetLarvae.length;
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

    function getInfected(address _user) public view returns (uint256 count) {
        uint256[] memory ids = micro.getUserIds(_user, 3, false);
        for (uint256 i; i < ids.length; i++) {
            if (micro.s(ids[i]).hp == 1) {
                count++;
            }
        }
    }

    function healSoldiers(uint256 _amount) public {
        require(_amount > 0);
        uint256 infected = getInfected(msg.sender);
        require(infected >= _amount);
        require(
            micro.funghiBalance(msg.sender) >
                infected * micro.tariff().soldierHeal
        );
        uint256[] memory ids = micro.getUserIds(msg.sender, 3, false);
        for (uint256 i; i < ids.length; i++) {
            if (micro.s(ids[i]).hp == 1 && _amount > 0) {
                micro.spendFunghi(
                    3,
                    3,
                    msg.sender,
                    _amount * micro.tariff().soldierHeal
                );
                micro.healSoldier(3, 3, ids[i]);
                _amount--;
            }
        }
    }
}
