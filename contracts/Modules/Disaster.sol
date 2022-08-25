//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IMicroColonies.sol";
import "../Interfaces/ITournament.sol";

contract Disaster is Initializable {
    IMicroColonies private micro;
    ITournament private tournament;

    mapping(uint256 => uint256) prices;
    mapping(uint256 => bool) used;

    event Revolution(address indexed _user, uint256 _ants);
    event WaspAttack(address indexed _user, uint256 _ants);
    event Fire(address indexed _user, uint256 _ants);
    event Infection(address indexed _user, uint256 _ants);
    event AntEater(address indexed _user, uint256 _ants);
    event DungBeetle(address indexed _user); // add amount?
    event SpiderWeb(address indexed _user, uint256 _ants);
    event Termite(address indexed _user, uint256 _funghi);
    event Flood(address indexed _user, uint256 _nest);
    event Resin(address indexed _user, uint256 _ants);
    event Freeze(address indexed _user); // add amount?
    event Strawberry(address indexed _user); // add amount?

    function initialize(address _micro) external initializer {
        micro = IMicroColonies(_micro);
        tournament = ITournament(msg.sender);
        prices[0] = 0;
        // ..
    }

    function involves(uint256[] memory array, uint256 object)
        private
        pure
        returns (bool)
    {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == object) {
                return (true);
            }
        }
        return false;
    }

    function sale(uint256 _id) private {
        IERC20(tournament.token()).transferFrom(
            msg.sender,
            tournament.treasury(),
            prices[_id]
        );
    }

    function revolution() external {
        sale(0);
        address[] memory p = tournament.participants();
        uint256 killed;
        for (uint256 i; i < p.length; i++) {
            uint256[] memory ids = micro.getUserIds(p[i], 0, false);
            for (uint256 j = 1; j < ids.length; j++) {
                micro.kill(p[i], 0, 0, ids[j]);
                killed++;
            }
        }
        emit Revolution(msg.sender, killed);
    }

    function wasp() external {
        sale(1);
        address[] memory players = tournament.participants();
        uint256 killed;
        for (uint256 i; i < players.length; i++) {
            uint256[] memory ids = micro.getUserIds(players[i], 5, false);
            uint256 missionCount = micro.getUserMissions(players[i], 5).length;
            uint256[] memory missionBuffer = new uint256[](missionCount);
            uint256 counter;
            for (uint256 j = 1; j < ids.length; j++) {
                bool passive = micro.p(ids[j]).mission.missionFinalized;
                uint256 missionId = micro.p(ids[j]).mission.missionId;
                bool involve = involves(missionBuffer, missionId);
                if (!passive && !involve) {
                    micro.finalizeMission(players[i], 0, 5, ids[j]);
                    missionBuffer[counter] = missionId;
                    counter++;
                }
                micro.kill(players[i], 0, 5, ids[j]);
                killed++;
            }
        }
        emit WaspAttack(msg.sender, killed);
    }

    function fire() external {
        sale(2);
        address[] memory p = tournament.participants();
        uint256 killed;
        for (uint256 i; i < p.length; i++) {
            for (uint256 j; j < 6; j++) {
                uint256[] memory m = micro.getUserMissions(p[i], j);
                for (uint256 z; z < m.length; z++) {
                    uint256[] memory ids = micro.getMissionIds(p[i], j, m[z]);
                    micro.finalizeMission(p[i], 0, j, m[z]);
                    for (uint256 x; x < ids.length; x++) {
                        micro.kill(p[i], 0, j, ids[x]);
                        killed++;
                    }
                }
            }
        }
        emit Fire(msg.sender, killed);
    }

    function infection() external {
        sale(3);
        address[] memory players = tournament.participants();
        uint256 zombified;
        for (uint256 i; i < players.length; i++) {
            uint256[] memory ids = micro.getUserIds(players[i], 3, false);
            uint256 missionCount = micro.getUserMissions(players[i], 3).length;
            uint256[] memory missionBuffer = new uint256[](missionCount);
            uint256 counter;
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 hp = micro.s(ids[j]).hp;
                if (hp != 0) {
                    bool passive = micro.p(ids[j]).mission.missionFinalized;
                    uint256 missionId = micro.p(ids[j]).mission.missionId;
                    bool involve = involves(missionBuffer, missionId);
                    if (!passive && !involve) {
                        micro.finalizeMission(players[i], 0, 5, ids[j]);
                        missionBuffer[counter] = missionId;
                        counter++;
                    }
                    for (uint256 k; k < hp; k++) {
                        micro.decreaseHP(0, 3, ids[j]);
                    }
                    zombified++;
                }
            }
        }
        emit Infection(msg.sender, zombified);
    }

    function anteater() external {
        sale(4);
        address[] memory players = tournament.participants();
        uint256 killed;
        for (uint256 i; i < players.length; i++) {
            uint256[] memory ids = micro.getUserIds(players[i], 2, false);
            for (uint256 j = 0; j < ids.length; j++) {
                micro.kill(players[i], 0, 2, ids[j]);
                killed++;
            }
        }
        emit AntEater(msg.sender, killed);
    }

    function dungbeetle() external {
        sale(5);
        micro.inhibit(0, 3, 4, true);
        emit DungBeetle(msg.sender);
    }

    function spiderweb() external {
        sale(6);
        address[] memory players = tournament.participants();
        uint256 killed;
        for (uint256 i; i < players.length; i++) {
            uint256[] memory ids = micro.getUserIds(players[i], 4, false);
            for (uint256 j = 0; j < ids.length; j++) {
                micro.kill(players[i], 0, 4, ids[j]);
                killed++;
            }
        }
        emit SpiderWeb(msg.sender, killed);
    }

    function termite() external {
        sale(7);
        address[] memory players = tournament.participants();
        uint256 slashed;
        for (uint256 i; i < players.length; i++) {
            uint256 balance = micro.funghiBalance(players[i]);
            if (balance != 0) {
                micro.spendFunghi(0, 0, players[i], balance / 2);
                slashed += balance / 2;
            }
        }
        emit Termite(msg.sender, slashed);
    }

    function flood() external {
        sale(8);
        address[] memory players = tournament.participants();
        uint256 demolished;
        for (uint256 i; i < players.length; i++) {
            uint256 capacity = micro.capacity(msg.sender);
            uint256 nested = micro.nested(msg.sender);
            if (capacity - nested != 0) {
                micro.decreaseCapacity(0, 0, players[i], capacity - nested);
                demolished += capacity - nested;
            }
        }
        emit Flood(msg.sender, demolished);
    }

    function resin() external {
        sale(9);
        address[] memory players = tournament.participants();
        uint256 healed;
        for (uint256 i; i < players.length; i++) {
            uint256[] memory ids = micro.getUserIds(players[i], 3, false);
            uint256 missionCount = micro.getUserMissions(players[i], 3).length;
            uint256[] memory missionBuffer = new uint256[](missionCount);
            uint256 counter;
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 hp = micro.s(ids[j]).hp;
                if (hp != 0) {
                    bool passive = micro.p(ids[j]).mission.missionFinalized;
                    uint256 missionId = micro.p(ids[j]).mission.missionId;
                    bool involve = involves(missionBuffer, missionId);
                    if (!passive && !involve) {
                        micro.finalizeMission(players[i], 0, 5, ids[j]);
                        missionBuffer[counter] = missionId;
                        counter++;
                    }
                    micro.healSoldier(0, 3, ids[j]);
                    healed++;
                }
            }
        }
        emit Resin(msg.sender, healed);
    }

    function freeze() external {
        sale(10);
        for (uint256 i; i < 6; i++) {
            micro.inhibit(0, i, 4, false);
        }

        emit Freeze(msg.sender);
    }

    function strawberry() external {
        sale(11);
        address[] memory players = tournament.participants();
        for (uint256 i; i < players.length; i++) {
            micro.matingBoost(players[i], 0, 0);
        }
        emit Strawberry(msg.sender);
    }
}
