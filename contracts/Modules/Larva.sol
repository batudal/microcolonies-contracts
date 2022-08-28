//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Interfaces/IMicroColonies.sol";
import "../Interfaces/ITournament.sol";
import "hardhat/console.sol";

contract Larva is Initializable {
    IMicroColonies private micro;
    ITournament private tournament;

    function initialize(address _micro) external initializer {
        micro = IMicroColonies(_micro);
        tournament = ITournament(msg.sender);
    }

    function isBoosted(address _user, uint256 _id) public view returns (bool) {
        uint256[] memory ids = micro.getMissionIds(_user, 1, _id);
        return false;
        // return
        //     (micro.l(id).mission.missionTimestamp >
        //         micro.lollipops(_user).timestamp &&
        //         micro.l(id).mission.missionTimestamp <=
        //         (micro.lollipops(_user).timestamp +
        //             micro.schedule().lollipopDuration))
        //         ? true
        //         : false;
    }

    function incubate(uint256 _amount, uint256 _feedAmount) public {
        uint256[] memory larvae = micro.getUserIds(msg.sender, 1, true);
        require(_amount <= larvae.length, "Not enough larvae");
        require(
            micro.funghiBalance(msg.sender) >=
                _feedAmount * micro.tariff().larvaPortion,
            "You don't have enough $Funghi"
        );

        if (_feedAmount > 0) {
            micro.spendFunghi(
                1,
                1,
                msg.sender,
                micro.tariff().larvaPortion * _feedAmount
            );
        }
        uint256 missionId = micro.createMission(msg.sender, 1, 1);
        for (uint256 i; i < _amount; i++) {
            uint256 missionType = _feedAmount > 0 ? 1 : 0;
            micro.addToMission(
                msg.sender,
                1,
                1,
                missionType,
                larvae[i],
                missionId
            );
            _feedAmount = _feedAmount > 0 ? _feedAmount - 1 : 0;
        }
        micro.earnXp(1, 1, msg.sender, _amount);
    }

    function hatch(uint256 _id) public {
        uint256[] memory ids = micro.getMissionIds(msg.sender, 1, _id);
        require(
            ids.length <= micro.capacity(msg.sender) - micro.nested(msg.sender),
            "You don't have enough nest capacity."
        );
        for (uint256 i = 0; i < ids.length; i++) {
            _hatch(msg.sender, ids[i]);
        }
        micro.finalizeMission(msg.sender, 1, 1, _id);
    }

    function _hatch(address _user, uint256 _id) private {
        uint16 modulo = micro.l(_id).mission.missionType == 1 ? 50 : 100;
        uint8 speed = isBoosted(_user, _id) ? 2 : 1;
        require(micro.l(_id).mission.missionTimestamp > 0);
        require(
            block.timestamp - micro.l(_id).mission.missionTimestamp >
                micro.schedule().incubation / speed
        );
        require(!micro.l(_id).mission.missionFinalized);
        uint256 nonce = micro.setNonce(1, 1) % modulo;
        require(micro.nested(_user) < micro.capacity(_user));
        if (nonce < 3) {
            micro.print(_user, 5, 5, 1);
            emit Hatch(_user, 5);
        } else if (nonce >= 3 && nonce < 18) {
            micro.print(_user, 4, 4, 1);
            emit Hatch(_user, 4);
        } else if (nonce >= 18 && nonce < 33) {
            micro.print(_user, 3, 3, 1);
            emit Hatch(_user, 3);
        } else {
            micro.print(_user, 2, 2, 1);
            emit Hatch(_user, 2);
        }
        micro.kill(_user, 1, 1, _id);
    }

    event Hatch(address _user, uint256 _type);
}
