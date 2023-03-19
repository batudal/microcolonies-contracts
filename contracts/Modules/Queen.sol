//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Interfaces/IMicroColonies.sol";
import "../Interfaces/ITournament.sol";
import "hardhat/console.sol";

contract Queen is Initializable {
    IMicroColonies private micro;
    ITournament private tournament;
    uint256[3] public fert;

    function initialize(address _micro) external initializer {
        micro = IMicroColonies(_micro);
        tournament = ITournament(msg.sender);
        fert = [5, 7, 9];
    }

    function getQueenEpochs(uint256 _id) public view returns (uint256 epochs) {
        epochs =
            (block.timestamp - micro.q(_id).timestamp) /
            tournament.epochDuration();
    }

    function getTimeToNext(uint256 _id) public view returns (uint256 time) {
        uint256 epochs = getQueenEpochs(_id);
        if (epochs >= fert[micro.q(_id).level - 1]) {
            time = 0;
        } else {
            uint256 epochsLeft = fert[micro.q(_id).level - 1] - epochs - 1;
            uint256 max = micro.q(_id).timestamp +
                tournament.epochDuration() *
                fert[micro.q(_id).level - 1];
            uint256 nextLaying = max -
                ((epochsLeft) * tournament.epochDuration());
            time = nextLaying - block.timestamp;
        }
    }

    function claimAllEggs() public {
        uint256[] memory ids = micro.getUserIds(msg.sender, 0, false);
        for (uint256 i; i < ids.length; i++) {
            claimEggs(ids[i]);
        }
    }

    function claimEggs(uint256 _id) public {
        uint256 deserved = eggsLaid(_id) - micro.q(_id).eggs;
        if (deserved > 0) {
            micro.addEggs(0, _id, deserved);
            micro.print(msg.sender, 1, deserved);
            micro.earnXp(0, msg.sender, deserved);
        }
    }

    function eggsLaid(uint256 _id) public view returns (uint256 eggs) {
        uint256 epochs = getQueenEpochs(_id);
        uint256 initEggs = fert[micro.q(_id).level - 1];
        if (epochs > initEggs) {
            epochs = initEggs;
        }
        for (uint256 i = 0; i < epochs; i++) {
            eggs += initEggs;
            initEggs -= 1;
        }
    }

    function feedQueen(uint256 _id) public {
        claimEggs(_id);
        uint256 epochs = (block.timestamp - micro.q(_id).timestamp) /
            tournament.epochDuration();
        if (fert[micro.q(_id).level] < epochs) {
            epochs = fert[micro.q(_id).level];
        }
        uint256 amount = epochs * micro.tariff().queenPortion;
        micro.resetQueen(0, 0, _id);
        micro.spendFunghi(0, msg.sender, amount);
        micro.earnXp(0, msg.sender, epochs);
    }

    function queenUpgrade(uint256 _id) public {
        uint256 amount = micro.q(_id).level == 1
            ? micro.tariff().queenUpgrade
            : micro.tariff().queenUpgrade * 3;
        require(
            micro.feromonBalance(msg.sender) >= amount,
            "Not enough feromon."
        );
        require(micro.q(_id).level < 3);
        claimEggs(_id);
        feedQueen(_id);
        micro.spendFeromon(0, msg.sender, amount);
        micro.queenLevelup(_id, 0);
    }

    function getQueenEnergy(uint256 _id) public view returns (uint256 energy) {
        uint256 max = tournament.epochDuration() * fert[micro.q(_id).level - 1];
        uint256 diff = block.timestamp - micro.q(_id).timestamp;
        if (diff > max) {
            energy = 0;
        } else {
            energy = ((max - diff) * 100) / max;
        }
    }
}
