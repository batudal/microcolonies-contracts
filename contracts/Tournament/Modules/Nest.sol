function getHomelessAntCount(address _user)
    public
    view
    returns (uint256 _homelessAntCount)
{
    uint256 _homelessWorkerCount = worker.getHomelessCount(_user);
    uint256 _homelessSoldierCount = soldier.getHomelessCount(_user);
    uint256 _homelessMaleCount = male.getHomelessCount(_user);
    uint256 _homelessPrincessCount = princess.getHomelessCount(_user);
    uint256 _homelessQueenCount = queen.getHomelessCount(_user);
    _homelessAntCount =
        _homelessWorkerCount +
        _homelessSoldierCount +
        _homelessMaleCount +
        _homelessPrincessCount +
        _homelessQueenCount;
    return _homelessAntCount;
}

function expandNest(uint256 _amount) public {
    uint256[] memory availableWorkerList = worker.getAvailableWorkers(
        msg.sender
    );
    require(_amount <= availableWorkerList.length);
    uint256[] memory workerList = new uint256[](_amount);
    uint256 _workerOnMission = 0;
    for (uint256 j = 0; j < _amount; j++) {
        worker.setBuildMission(availableWorkerList[j], true);
        worker.setBuildDate(availableWorkerList[j], block.timestamp);
        worker.transferFrom(msg.sender, address(this), availableWorkerList[j]);
        workerList[_workerOnMission] = availableWorkerList[j];
        _workerOnMission++;
        feromon.mint(msg.sender, 1);
    }
    uint256 speed = getSpeed(msg.sender);
    worker.addMission(msg.sender, workerList, 1, false, speed);
}

function increaseCapacity(address _user) public {
    playerToAvailableSpace[_user] += 5;
    playerToCapacity[_user] += 5;
}

function decreaseAvailableSpace(address _user) public {
    playerToAvailableSpace[_user] -= 1;
}

function increaseAvailableSpace(address _user) public {
    playerToAvailableSpace[_user] += 1;
}

function claimAndIncreaseSpace(uint256 _missionIndex) public {
    uint256[] memory builders = worker.getMissionIds(msg.sender, _missionIndex);
    uint256 missionEnd = worker.getMissionEnd(msg.sender, _missionIndex);

    for (uint256 i; i < builders.length; i++) {
        if (missionEnd <= block.timestamp) {
            increaseCapacity(msg.sender);
            worker.setBuildMission(builders[i], false);
            worker.transferFrom(address(this), msg.sender, builders[i]);
            worker.reduceHP(msg.sender, builders[i]);
        }
    }
    worker.finalizeMission(msg.sender, _missionIndex);
}

function getPopulation() public view returns (uint256 count) {
    count += worker.getWorkers(msg.sender).length;
    count += soldier.getSoldiers(msg.sender).length;
    count += queen.getQueens(msg.sender).length;
    count += male.getMales(msg.sender).length;
    count += princess.getPrincesses(msg.sender).length;
}
