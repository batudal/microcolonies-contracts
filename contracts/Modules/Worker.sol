//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Interfaces/IMicroColonies.sol";

contract Worker is Initializable {
    IMicroColonies private micro;

    function initialize(address _micro) external initializer {
        micro = IMicroColonies(_micro);
    }

    // worker fxns
    function convert(uint256 _amount) public {
        uint256[] memory ids = micro.getUserIds(msg.sender, 2, true);
        require(_amount <= ids.length, "Not enough workers.");
        require(
            _amount * micro.tariff().conversion <=
                micro.feromonBalance(msg.sender),
            "Not enough feromons."
        );
        uint256 missionId = micro.createMission(msg.sender, 2, 2);
        for (uint256 i; i < _amount; i++) {
            micro.addToMission(msg.sender, 2, 2, 2, ids[i], missionId);
        }
        micro.earnXp(2, 2, msg.sender, _amount);
    }

    function claimConverted(uint256 _id) public {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 2, _id);
        uint8 speed = isBoosted(msg.sender, _id) ? 2 : 1;
        require(micro.w(ids[0]).mission.missionTimestamp != 0);
        require(
            micro.w(ids[0]).mission.missionTimestamp +
                micro.schedule().conversion /
                speed <
                block.timestamp
        );
        require(!micro.w(ids[0]).mission.missionFinalized);
        for (uint256 i; i < ids.length; i++) {
            micro.kill(msg.sender, 2, 2, ids[i]);
        }
        micro.print(msg.sender, 2, 3, ids.length);
        micro.finalizeMission(msg.sender, 2, 2, _id);
    }

    function farm(uint256 _amount) public {
        uint256[] memory ids = micro.getUserIds(msg.sender, 2, true);
        require(_amount <= ids.length, "Not enough workers.");
        uint256 missionId = micro.createMission(msg.sender, 2, 2);
        for (uint256 i; i < _amount; i++) {
            micro.addToMission(msg.sender, 2, 2, 0, ids[i], missionId);
        }
        micro.earnXp(2, 2, msg.sender, _amount);
    }

    function claimFarmed(uint256 _id) public {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 2, _id);
        uint8 speed = isBoosted(msg.sender, _id) ? 2 : 1;
        require(
            micro.w(ids[0]).mission.missionTimestamp +
                micro.schedule().workerFarm /
                speed <
                block.timestamp
        );
        require(!micro.w(ids[0]).mission.missionFinalized);
        micro.earnFunghi(
            2,
            2,
            msg.sender,
            ids.length * micro.tariff().farmReward
        );
        for (uint256 i; i < ids.length; i++) {
            if (micro.w(ids[i]).hp == 1) {
                micro.kill(msg.sender, 2, 2, ids[i]);
            } else {
                micro.decreaseHP(2, 2, ids[i]);
            }
        }
        micro.finalizeMission(msg.sender, 2, 2, _id);
    }

    function build(uint256 _amount) public {
        uint256[] memory ids = micro.getUserIds(msg.sender, 2, true);
        require(_amount <= ids.length, "Not enough workers.");
        uint256 missionId = micro.createMission(msg.sender, 2, 2);
        for (uint256 i; i < _amount; i++) {
            micro.addToMission(msg.sender, 2, 2, 1, ids[i], missionId);
        }
        micro.earnXp(2, 2, msg.sender, _amount);
    }

    function claimBuilt(uint256 _id) public {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 2, _id);
        uint8 speed = isBoosted(msg.sender, _id) ? 2 : 1;
        require(micro.w(ids[0]).mission.missionTimestamp != 0);
        require(
            micro.w(ids[0]).mission.missionTimestamp +
                micro.schedule().workerBuild /
                speed <
                block.timestamp
        );
        require(!micro.w(ids[0]).mission.missionFinalized);
        micro.increaseCapacity(
            2,
            2,
            msg.sender,
            ids.length * micro.tariff().buildReward
        );
        for (uint256 i; i < ids.length; i++) {
            if (micro.w(ids[i]).hp == 1) {
                micro.kill(msg.sender, 2, 2, ids[i]);
            } else {
                micro.decreaseHP(2, 2, ids[i]);
            }
        }
        micro.finalizeMission(msg.sender, 2, 2, _id);
    }

    function isBoosted(address _user, uint256 _id) public view returns (bool) {
        uint256 id = micro.getMissionIds(_user, 2, _id)[0];
        return false;
        // return
        //     (micro.w(id).mission.missionTimestamp >
        //         micro.lollipops(_user).timestamp &&
        //         micro.w(id).mission.missionTimestamp <=
        //         (micro.lollipops(_user).timestamp +
        //             micro.schedule().lollipopDuration))
        //         ? true
        //         : false;
    }
}
