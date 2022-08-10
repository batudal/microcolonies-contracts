function setPlayerToTarget(address _user, address _target) public {
    playerToTarget[_user] = _target;
}

function findTarget(uint256 _amount) public {
    uint256[] memory availableSoldierList = soldier.getAvailableSoldiers(
        msg.sender
    );
    require(_amount <= availableSoldierList.length, "Not enough soldiers.");
    uint256[] memory soldierList = new uint256[](_amount);
    uint256 _soldierOnMission = 0;
    for (uint256 i; i < _amount; i++) {
        soldier.setRaidMission(availableSoldierList[i], true);
        soldier.setRaidDate(availableSoldierList[i], block.timestamp);
        soldier.transferFrom(
            msg.sender,
            address(this),
            availableSoldierList[i]
        );
        soldierList[_soldierOnMission] = availableSoldierList[i];
        _soldierOnMission++;
        feromon.mint(msg.sender, 1);
        soldier.infectionSpread(msg.sender);
    }
    uint256 speed = getSpeed(msg.sender);
    soldier.addMission(msg.sender, soldierList, false, speed);
}

function otherParticipants(address _user)
    public
    view
    returns (address[] memory _participants)
{
    uint256 participantAdded = 0;
    _participants = new address[](participants.length - 1);
    for (uint256 i = 0; i < participants.length; i++) {
        if (participants[i] != _user) {
            _participants[participantAdded] = participants[i];
            participantAdded++;
        }
    }
    return _participants;
}

function revealTarget(uint256 _missionId)
    public
    view
    returns (address _target)
{
    uint256 _end = soldier.getMissionEnd(msg.sender, _missionId);
    require(_end < block.timestamp, "Mission is not over yet.");
    address[] memory remainingParticipants = otherParticipants(msg.sender);
    uint256 prob = uint256(keccak256(abi.encodePacked(msg.sender, nonce))) %
        remainingParticipants.length;
    _target = remainingParticipants[prob];
    return _target;
}

function retreatSoldiers(uint256 _missionId) public {
    uint256[] memory missionParticipants = soldier.getMissionParticipantList(
        msg.sender,
        _missionId
    );
    uint256 _end = soldier.getMissionEnd(msg.sender, _missionId);
    for (uint256 i; i < missionParticipants.length; i++) {
        if (_end < block.timestamp) {
            soldier.setRaidMission(missionParticipants[i], false);
            soldier.transferFrom(
                address(this),
                msg.sender,
                missionParticipants[i]
            );
        }
    }
    soldier.finalizeMission(msg.sender, _missionId);
}

function claimStolenLarvae(uint256 _missionId) public {
    uint256[] memory missionParticipants = soldier.getMissionParticipantList(
        msg.sender,
        _missionId
    );
    uint256 targetSoldierCount = soldier
        .getAvailableSoldiers(revealTarget(_missionId))
        .length;
    uint256[] memory targetLarvae = larva.getLarvae(revealTarget(_missionId));
    uint256 attackerSoldierCount = soldier.getMissionPartipants(
        msg.sender,
        _missionId
    );
    (uint256 prize, uint256 bonus) = soldier.battle(
        attackerSoldierCount,
        targetSoldierCount,
        targetLarvae.length
    );

    for (uint256 i = 0; i < missionParticipants.length; i++) {
        if (soldier.getMissionEnd(msg.sender, _missionId) < block.timestamp) {
            soldier.increaseDamage(missionParticipants[i]);
            soldier.setRaidMission(missionParticipants[i], false);
            soldier.transferFrom(
                address(this),
                msg.sender,
                missionParticipants[i]
            );
        }
    }
    soldier.finalizeMission(msg.sender, _missionId);

    if (prize == 0 && bonus == 0) {
        return ();
    }
    // prize = prize >= targetLarvae.length ? targetLarvae.length : prize;
    uint256[] memory larvaToBeBurnt = new uint256[](prize + bonus);
    uint256 larvaeAdded = 0;
    for (uint256 i = 0; i < prize + bonus; i++) {
        larvaToBeBurnt[larvaeAdded] = targetLarvae[i];
        larvaeAdded++;
    }
    for (uint256 i = 0; i < prize + bonus; i++) {
        larva.getStolen(
            revealTarget(_missionId),
            msg.sender,
            larvaToBeBurnt[i]
        );
    }
}
