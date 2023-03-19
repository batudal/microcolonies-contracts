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

    function initialize(address _micro) external initializer {
        micro = IMicroColonies(_micro);
        tournament = ITournament(msg.sender);
    }

    function mate(uint256 _amount) public {
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

    function claimMated(uint256 _id) public {
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
        return false;
        // return
        //     (micro.p(id).mission.missionTimestamp >
        //         micro.lollipops(_user).timestamp &&
        //         micro.p(id).mission.missionTimestamp <=
        //         (micro.lollipops(_user).timestamp +
        //             micro.schedule().lollipopDuration))
        //         ? true
        //         : false;
    }

    function onSeason(address _user, uint256 _id) public view returns (bool) {
        (uint256[4] memory start, uint256[4] memory end) = seasonDates();
        uint256[] memory ids = micro.getMissionIds(_user, 5, _id);
        uint256 timestamp = micro.p(ids[0]).mission.missionTimestamp;
        for (uint256 i; i < 4; i++) {
            if ((timestamp >= start[i]) && (timestamp <= end[i])) {
                return true;
            }
        }
        return false;
    }

    function seasonDates()
        public
        view
        returns (uint256[4] memory start, uint256[4] memory end)
    {
        uint256 date = tournament.startDate();
        uint256 tournamentDuration = tournament.tournamentDuration();
        for (uint256 i; i < 4; i++) {
            start[i] = date + (tournamentDuration / 4) * i;
            end[i] = start[i] + tournamentDuration / 16;
        }
    }
}
