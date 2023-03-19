//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Interfaces/IMicroColonies.sol";
import "../Interfaces/ITournament.sol";
import "hardhat/console.sol";

contract Princess is Initializable {
    IMicroColonies private micro;
    ITournament private tournament;

    mapping(uint256 => uint256) private idMap;
    mapping(uint256 => uint256) private males;

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
    }

    function mate(uint256 _amount) public checkState {
        uint256[] memory ids = micro.getUserIds(msg.sender, 5, true);
        uint256[] memory maleIds = micro.getUserIds(msg.sender, 4, true);
        require(_amount <= ids.length, "Not enough princesses.");
        uint256 missionId = micro.createMission(msg.sender, 5);
        uint256 maleMissionId = micro.createMission(msg.sender, 4);
        for (uint256 i; i < _amount; i++) {
            micro.addToMission(msg.sender, 5, 0, ids[i], missionId);
        }
        for (uint256 i; i < maleIds.length; i++) {
            micro.addToMission(msg.sender, 4, 0, maleIds[i], maleMissionId);
        }
        micro.earnXp(5, msg.sender, _amount + maleIds.length);
        idMap[missionId] = maleMissionId;
        males[missionId] = maleIds.length;
    }

    function claimMated(uint256 _id) public checkState {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 5, _id);
        uint256[] memory maleIds = micro.getMissionIds(
            msg.sender,
            4,
            idMap[_id]
        );
        uint8 speed = isBoosted(msg.sender, _id) ? 2 : 1;
        require(micro.p(ids[0]).mission.missionTimestamp != 0);
        require(
            micro.p(ids[0]).mission.missionTimestamp +
                micro.schedule().mating /
                speed <
                block.timestamp
        );
        require(!micro.p(ids[0]).mission.missionFinalized);
        uint256 princesses = ids.length;
        uint256 threshold = onSeason(msg.sender, _id) ? 1 : 4;
        uint256 nonce = micro.setNonce(5) % 5;
        for (uint256 i; i < maleIds.length; i++) {
            micro.kill(msg.sender, 4, maleIds[i]);
            if (princesses > 0) {
                if (nonce >= threshold) {
                    micro.kill(msg.sender, 5, ids[princesses - 1]);
                    micro.print(msg.sender, 0, 1);
                    princesses--;
                }
            } else {
                break;
            }
        }
    }

    function isBoosted(address _user, uint256 _id) public view returns (bool) {
        uint256 id = micro.getMissionIds(_user, 5, _id)[0];
        return
            (micro.p(id).mission.missionTimestamp >
                micro.lollipops(_user).timestamp &&
                micro.p(id).mission.missionTimestamp <=
                (micro.lollipops(_user).timestamp +
                    micro.schedule().lollipopDuration))
                ? true
                : false;
    }

    function onSeason(address _user, uint256 _id) public view returns (bool) {
        uint256 date = tournament.startDate();
        uint256 duration = tournament.tournamentDuration();
        uint256 indays = duration / 86400;
        uint256[] memory ids = micro.getMissionIds(_user, 5, _id);
        uint256 timestamp = micro.p(ids[0]).mission.missionTimestamp;
        for (uint256 i; i < indays; i++) {
            if (
                (timestamp >= (date + (i * duration) / indays)) &&
                (timestamp <= (date + (i * duration) / indays) + 3600)
            ) {
                return true;
            }
        }
        return false;
    }

    function seasonDates()
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 date = tournament.startDate();
        uint256 duration = tournament.tournamentDuration();
        uint256 indays = duration / 86400;
        uint256[] memory start = new uint256[](indays);
        uint256[] memory end = new uint256[](indays);
        for (uint256 i = 0; i < indays; i++) {
            start[i] = date + (i * duration) / indays;
            end[i] = start[i] + 3600;
        }
        return (start, end);
    }
}
