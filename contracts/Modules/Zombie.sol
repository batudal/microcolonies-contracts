//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Interfaces/IMicroColonies.sol";
import "../Interfaces/ITournament.sol";
import "../Helpers/Quick.sol";

contract Zombie is Initializable {
    IMicroColonies private micro;
    ITournament private tournament;
    uint256 private nonce;

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

    function initialize(address _micro) external initializer {
        micro = IMicroColonies(_micro);
        tournament = ITournament(msg.sender);
        nonce = 42;
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

    function harvest(uint256 _amount) public checkState {
        uint256[] memory ids = micro.getUserIds(msg.sender, 6, true);
        require(_amount <= ids.length, "Not enough zombies.");
        uint256 missionId = micro.createMission(msg.sender, 6);
        micro.earnXp(3, msg.sender, _amount);
        for (uint256 i; i < ids.length; i++) {
            if (_amount > 0) {
                micro.addToMission(msg.sender, 6, 0, ids[i], missionId);
                _amount--;
            }
        }
    }

    function claimHarvested(uint256 _id) public checkState {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 6, _id);
        uint8 speed = isBoosted(msg.sender, _id) ? 2 : 1;
        require(micro.z(ids[0]).mission.missionTimestamp != 0);
        require(
            micro.z(ids[0]).mission.missionTimestamp +
                micro.schedule().zombieHarvest /
                speed <
                block.timestamp
        );
        require(
            !micro.z(ids[0]).mission.missionFinalized,
            "Mission already is finalized."
        );
        for (uint256 i; i < ids.length; i++) {
            micro.kill(msg.sender, 6, ids[i]);
        }
        micro.earnFunghi(
            6,
            msg.sender,
            ids.length * micro.tariff().zombieHarvest
        );
        micro.finalizeMission(msg.sender, 6, _id);
    }

    function defend(uint256 _amount) public checkState {
        uint256[] memory ids = micro.getUserIds(msg.sender, 6, true);
        require(_amount <= ids.length, "Not enough zombies.");
        uint256 missionId = micro.createMission(msg.sender, 6);
        micro.earnXp(3, msg.sender, _amount);
        for (uint256 i; i < ids.length; i++) {
            if (_amount > 0) {
                micro.addToMission(msg.sender, 6, 1, ids[i], missionId);
                _amount--;
            }
        }
    }

    function defenders(address _user)
        public
        view
        returns (uint256[] memory defendings)
    {
        uint256[] memory ids = micro.getUserIds(_user, 6, false);
        uint256 defending;
        for (uint256 i; i < ids.length; i++) {
            if (
                micro.z(ids[i]).mission.missionType == 1 &&
                micro.z(ids[i]).mission.missionTimestamp +
                    micro.schedule().zombieGuard >
                block.timestamp
            ) {
                defending++;
            }
        }
        defendings = new uint256[](defending);
        for (uint256 j; j < ids.length; j++) {
            if (
                micro.z(ids[j]).mission.missionType == 1 &&
                micro.z(ids[j]).mission.missionTimestamp +
                    micro.schedule().zombieGuard >
                block.timestamp
            ) {
                defendings[defending] = ids[j];
                defending--;
            }
        }
    }

    function getZombieCount(address _user, bool _available)
        public
        view
        returns (uint256 count)
    {
        uint256[] memory ids = micro.getUserIds(_user, 3, _available);
        for (uint256 i; i < ids.length; i++) {
            if (micro.s(ids[i]).hp == 0) {
                count++;
            }
        }
    }
}
