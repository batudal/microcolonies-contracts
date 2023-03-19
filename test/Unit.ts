import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades, network } from "hardhat";

const epoch = 21600;
let feedAmount = 0;
const farmReward = 80;
const workerBuild = 5;
const workerFarm = 1;
const buildReward = 5;
const conversionDuration = 1;
const soldierScout = 3;
const zombieHarvest = 5;
const harvestReward = 400;

describe("Unit Tests", function() {
  async function deployFixture() {
    // deploy mock erc20 and mint some
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Mock20 = await ethers.getContractFactory("Mock20");
    const mock20 = await Mock20.deploy();
    await mock20.mint(owner.address, ethers.utils.parseEther("100"));
    await mock20.mint(addr1.address, ethers.utils.parseEther("100"));
    await mock20.mint(addr2.address, ethers.utils.parseEther("100"));
    // microcolonies deploy
    const MicroColonies = await ethers.getContractFactory("MicroColonies");
    const microColonies = await MicroColonies.deploy();
    await microColonies.deployed();
    const init_microColonies = await microColonies.initialize("0",);
    await init_microColonies.wait();
    // queen deploy
    const Queen = await ethers.getContractFactory("Queen");
    const queen = await Queen.deploy();
    await queen.deployed();
    const init_queen = await queen.initialize(microColonies.address);
    await init_queen.wait();
    // larva deploy
    const Larva = await ethers.getContractFactory("Larva");
    const larva = await Larva.deploy();
    await larva.deployed();
    const init_larva = await larva.initialize(microColonies.address);
    await init_larva.wait();
    // worker deploy
    const Worker = await ethers.getContractFactory("Worker");
    const worker = await Worker.deploy();
    await worker.deployed();
    const init_worker = await worker.initialize(microColonies.address);
    await init_worker.wait();
    // soldier deploy
    const Soldier = await ethers.getContractFactory("Soldier");
    const soldier = await Soldier.deploy();
    await soldier.deployed();
    const init_soldier = await soldier.initialize(microColonies.address);
    await init_soldier.wait();
    // deploy princess
    const Princess = await ethers.getContractFactory("Princess");
    const princess = await Princess.deploy();
    await princess.deployed();
    const init_princess = await princess.initialize(microColonies.address);
    await init_princess.wait();
    // deploy zombie
    const Zombie = await ethers.getContractFactory("Zombie");
    const zombie = await Zombie.deploy();
    await zombie.deployed();
    const init_zombie = await zombie.initialize(microColonies.address);
    await init_zombie.wait();

    // deploy tournamentFactory
    const TournamentFactory = await ethers.getContractFactory("TournamentFactory");
    const tournamentFactory = await upgrades.deployProxy(TournamentFactory, [
      [microColonies.address, queen.address, larva.address, worker.address, soldier.address, princess.address, zombie.address],
    ]);
    await tournamentFactory.deployed();
    return {
      mock20,
      MicroColonies,
      Queen,
      Larva,
      Worker,
      Soldier,
      Princess,
      Zombie,
      tournamentFactory,
    };
  }
  async function createFixture() {
    const { mock20, MicroColonies, Queen, Larva, Worker, Soldier, Princess, Zombie, tournamentFactory } = await loadFixture(deployFixture);
    const [owner, addr1, addr2] = await ethers.getSigners();
    const now = Math.floor(Date.now() / 1000).toString();
    await tournamentFactory.createTournament("Title", 1, mock20.address, epoch, now, 10, 0);
    const tournamentAddr = (await tournamentFactory.getTournaments())[0];
    const Tournament = await ethers.getContractFactory("Tournament");
    const tournament = Tournament.attach(tournamentAddr);
    const tournamentContracts = await tournament.contracts();
    const microColonies = MicroColonies.attach(tournamentContracts.microColonies);
    const queen = Queen.attach(tournamentContracts.queen);
    const larva = Larva.attach(tournamentContracts.larva);
    const worker = Worker.attach(tournamentContracts.worker);
    const soldier = Soldier.attach(tournamentContracts.soldier);
    const princess = Princess.attach(tournamentContracts.princess);
    const zombie = Zombie.attach(tournamentContracts.zombie);
    return {
      mock20,
      microColonies,
      queen,
      larva,
      worker,
      soldier,
      princess,
      zombie,
      tournament,
      owner,
      addr1,
      addr2,
    };
  }
  async function hatch_Fixture() {
    const { mock20, microColonies, queen, larva, worker, soldier, princess, zombie, tournament, owner, addr1, addr2 } = await loadFixture(
      createFixture
    );
    await mock20.approve(tournament.address, 1);
    await tournament.enterTournament(`takezo_pack2`);
    await larva.incubate(19, feedAmount);
    const missions = await microColonies.getUserMissions(owner.address, 1);
    await network.provider.send("evm_increaseTime", [epoch + 10]);
    await network.provider.send("evm_mine");
    await larva.hatch(missions[0]);
    const queen_ids = await microColonies.getUserIds(owner.address, 0, false);
    const worker_ids = await microColonies.getUserIds(owner.address, 2, false);
    const soldier_ids = await microColonies.getUserIds(owner.address, 3, false);
    const zombie_ids = await microColonies.getUserIds(owner.address, 6, false);
    const male_ids = await microColonies.getUserIds(owner.address, 4, false);
    const princess_ids = await microColonies.getUserIds(owner.address, 5, false);
    return {
      mock20,
      microColonies,
      queen,
      larva,
      worker,
      soldier,
      zombie,
      princess,
      tournament,
      owner,
      addr1,
      addr2,
      queen_ids,
      worker_ids,
      soldier_ids,
      zombie_ids,
      male_ids,
      princess_ids,
    };
  }

  describe("Tournament Unit Tests", () => {
    it("Should enter tournament", async function() {
      const { mock20, tournament, microColonies, owner } = await loadFixture(createFixture);
      await mock20.approve(tournament.address, 1);
      await tournament.enterTournament("takezo_pack(1)",);
      const capacity = await microColonies.capacity(owner.address);
      expect(capacity).to.equal(20);
      const nested = await microColonies.nested(owner.address);
      expect(nested).to.equal(1);
      const all_queens = await microColonies.getUserIds(owner.address, 0, false);
      expect(all_queens.length).to.equal(1);
      expect(all_queens[0]).to.equal(0);
      const available_queens = await microColonies.getUserIds(owner.address, 0, true);
      expect(available_queens.length).to.equal(1);
      expect(available_queens[0]).to.equal(0);
      const all_larvae = await microColonies.getUserIds(owner.address, 1, false);
      expect(all_larvae.length).to.equal(19);
      expect(all_larvae[0]).to.equal(0);
      expect(all_larvae[18]).to.equal(18);
      const available_larvae = await microColonies.getUserIds(owner.address, 1, true);
      expect(available_larvae.length).to.equal(19);
      expect(available_larvae[0]).to.equal(0);
      expect(available_larvae[18]).to.equal(18);
    });
  });
  describe("Larva Unit Tests", () => {
    it("Should incubate", async () => {
      const { mock20, tournament, microColonies, larva, owner } = await loadFixture(createFixture);
      await mock20.approve(tournament.address, 1);
      await tournament.enterTournament("takezo_pack(0)");
      const feromon_pre = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      await larva.incubate(19, 0);
      const missions = await microColonies.getUserMissions(owner.address, 1);
      expect(missions.length).to.equal(1);
      const missionIds = await microColonies.getMissionIds(owner.address, 1, missions[0]);
      expect(missionIds.length).to.equal(19);
      const feromon_after = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      expect(feromon_after - feromon_pre).to.equal(missionIds.length);
    });
    it("Should hatch (0/19 fed)", async () => {
      const { mock20, tournament, microColonies, larva, owner } = await loadFixture(createFixture);
      await mock20.approve(tournament.address, 1);
      await tournament.enterTournament("takezo_pack(0)",);
      await larva.incubate(19, 0);
      const missions = await microColonies.getUserMissions(owner.address, 1);
      expect(missions.length).to.equal(1);
      const missionState = await microColonies.missionStates(owner.address, 1, missions[0]);
      expect(missionState).to.equal(1);
      const missionIds = await microColonies.getMissionIds(owner.address, 1, missions[0]);
      expect(missionIds.length).to.equal(19);
      await network.provider.send("evm_increaseTime", [epoch + 10]);
      await network.provider.send("evm_mine");
      expect(await microColonies.nested(owner.address)).to.equal(1);
      await larva.hatch(missions[0]);
      const missionState_after = await microColonies.missionStates(owner.address, 1, missions[0]);
      expect(missionState_after).to.equal(2);
      expect(await microColonies.nested(owner.address)).to.equal(20);
    });
    it("Should hatch (10/19 fed)", async () => {
      const { mock20, tournament, microColonies, larva, owner } = await loadFixture(createFixture);
      await mock20.approve(tournament.address, 1);
      await tournament.enterTournament("takezo_pack(0)",);
      expect(await microColonies.funghiBalance(owner.address)).to.equal("100000");
      await larva.incubate(19, 10);
      expect(await microColonies.funghiBalance(owner.address)).to.equal("96000");
      const missions = await microColonies.getUserMissions(owner.address, 1);
      expect(missions.length).to.equal(1);
      const missionIds = await microColonies.getMissionIds(owner.address, 1, missions[0]);
      expect(missionIds.length).to.equal(19);
      await network.provider.send("evm_increaseTime", [epoch + 10]);
      await network.provider.send("evm_mine");
      expect(await microColonies.nested(owner.address)).to.equal(1);
      await larva.hatch(missions[0]);
      expect(await microColonies.nested(owner.address)).to.equal(20);
    });
    it("Should hatch (19/20 fed)", async () => {
      const { mock20, tournament, microColonies, larva, owner } = await loadFixture(createFixture);
      await mock20.approve(tournament.address, 1);
      await tournament.enterTournament("takezo_pack(0)",);
      expect(await microColonies.funghiBalance(owner.address)).to.equal("100000");
      await larva.incubate(19, 19);
      expect(await microColonies.funghiBalance(owner.address)).to.equal("92400");
      const missions = await microColonies.getUserMissions(owner.address, 1);
      expect(missions.length).to.equal(1);
      const missionIds = await microColonies.getMissionIds(owner.address, 1, missions[0]);
      expect(missionIds.length).to.equal(19);
      await network.provider.send("evm_increaseTime", [epoch + 10]);
      await network.provider.send("evm_mine");
      expect(await microColonies.nested(owner.address)).to.equal(1);
      await larva.hatch(missions[0]);
      expect(await microColonies.nested(owner.address)).to.equal(20);
    });
  });
  describe("Worker Unit Tests", () => {
    it("Should farm and pay rewards", async () => {
      feedAmount = 0;
      const { microColonies, worker, worker_ids, owner } = await loadFixture(hatch_Fixture);
      expect(worker_ids.length).to.be.greaterThan(0);
      const feromon_pre = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      await worker.farm(worker_ids.length);
      const missions = await microColonies.getUserMissions(owner.address, 2);
      expect((await microColonies.getMissionIds(owner.address, 2, missions[0])).length).to.equal(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerFarm + 10]);
      await network.provider.send("evm_mine");
      const balance_pre = parseFloat((await microColonies.funghiBalance(owner.address)).toString());
      await worker.claimFarmed(missions[0]);
      const balance_after = parseFloat((await microColonies.funghiBalance(owner.address)).toString());
      expect(balance_after - balance_pre).to.equal(worker_ids.length * farmReward);
      const feromon_after = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      expect(feromon_after - feromon_pre).to.equal(worker_ids.length);
    });
    it("Should build and increase capacity", async () => {
      feedAmount = 0;
      const { microColonies, worker, worker_ids, owner } = await loadFixture(hatch_Fixture);
      expect(worker_ids.length).to.be.greaterThan(0);
      const feromon_pre = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      await worker.build(worker_ids.length);
      const missions = await microColonies.getUserMissions(owner.address, 2);
      expect((await microColonies.getMissionIds(owner.address, 2, missions[0])).length).to.equal(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerBuild + 10]);
      await network.provider.send("evm_mine");
      const capacity_pre = parseFloat((await microColonies.capacity(owner.address)).toString());
      await worker.claimBuilt(missions[0]);
      const capacity_after = parseFloat((await microColonies.capacity(owner.address)).toString());
      expect(capacity_after - capacity_pre).to.equal(worker_ids.length * buildReward);
      const feromon_after = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      expect(feromon_after - feromon_pre).to.equal(worker_ids.length);
    });
    it("Should convert to soldier", async () => {
      feedAmount = 0;
      const { microColonies, worker, worker_ids, soldier_ids, owner } = await loadFixture(hatch_Fixture);
      expect(worker_ids.length).to.be.greaterThan(1);
      const feromon_pre = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      const workers_pre = worker_ids.length;
      const soldiers_pre = soldier_ids.length;
      await worker.convert(2);
      const missions = await microColonies.getUserMissions(owner.address, 2);
      expect((await microColonies.getMissionIds(owner.address, 2, missions[0])).length).to.equal(2);
      await network.provider.send("evm_increaseTime", [epoch * conversionDuration + 10]);
      await network.provider.send("evm_mine");
      const claim_tx = await worker.claimConverted(missions[0]);
      await claim_tx.wait();
      const feromon_after = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      expect(feromon_after - feromon_pre).to.equal(2);
      const workers_after = parseFloat((await microColonies.getUserIds(owner.address, 2, false)).length.toString());
      expect(workers_pre - workers_after).to.equal(2);
      const soldiers_after = parseFloat((await microColonies.getUserIds(owner.address, 3, false)).length.toString());
      expect(soldiers_after - soldiers_pre).to.equal(2);
    });
    it("Should work with multiple simultaneous missions", async () => {
      feedAmount = 0;
      const { microColonies, worker, worker_ids, owner } = await loadFixture(hatch_Fixture);
      expect(worker_ids.length).to.be.greaterThan(0);
      await worker.farm(worker_ids.length);
      const missions = await microColonies.getUserMissions(owner.address, 2);
      expect((await microColonies.getMissionIds(owner.address, 2, missions[0])).length).to.equal(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerFarm + 10]);
      await network.provider.send("evm_mine");
      await worker.claimFarmed(missions[0]);
    });
  });
  // zombie defence integration!
  describe("Soldier Unit Tests", () => {
    it("Should scout and retreat", async () => {
      feedAmount = 19;
      const { microColonies, tournament, mock20, addr1, addr2, worker, worker_ids, soldier, soldier_ids, owner, larva } = await loadFixture(hatch_Fixture);
      expect(soldier_ids.length).to.be.greaterThan(1);
      await worker.build(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerBuild + 10]);
      await network.provider.send("evm_mine");
      const workerMissions = await microColonies.getUserMissions(owner.address, 2);
      await worker.claimBuilt(workerMissions[0]);
      const capacity = parseFloat((await microColonies.capacity(owner.address)).toString());
      const nested = parseFloat((await microColonies.nested(owner.address)).toString());
      expect(capacity - nested).to.be.greaterThan(soldier_ids.length);

      const addr1_mock20 = mock20.connect(addr1);
      await addr1_mock20.approve(tournament.address, 1);
      const addr1_tournament = tournament.connect(addr1);
      await addr1_tournament.enterTournament("Address 1",);
      const addr1_larva = larva.connect(addr1);
      await addr1_larva.incubate(19, 0);
      const addr1_missions = await microColonies.getUserMissions(addr1.address, 1);
      expect(addr1_missions.length).to.equal(1);

      const addr2_mock20 = mock20.connect(addr2);
      await addr2_mock20.approve(tournament.address, 1);
      const addr2_tournament = tournament.connect(addr2);
      await addr2_tournament.enterTournament("Address 2",);
      const addr2_larva = larva.connect(addr2);
      await addr2_larva.incubate(19, 0);

      const feromon_pre = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      const larva_pre = parseFloat((await microColonies.getUserIds(owner.address, 1, false)).length.toString());
      expect(larva_pre).to.equal(0);
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(2);
      await soldier.scout(soldier_ids.length);
      const missions = await microColonies.getUserMissions(owner.address, 3);
      expect((await microColonies.getMissionIds(owner.address, 3, missions[0])).length).to.equal(soldier_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      const target = await soldier.reveal(missions[0]);
      expect(target).to.equal(addr1.address);
      await soldier.retreat(missions[0]);
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(1);

      const larva_after = parseFloat((await microColonies.getUserIds(owner.address, 1, false)).length.toString());
      expect(larva_after).to.equal(larva_pre);
      const feromon_after = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      expect(feromon_after - feromon_pre).to.equal(soldier_ids.length);
    });
    it("Should scout and attack a target", async () => {
      feedAmount = 19;
      const { microColonies, tournament, mock20, addr1, addr2, worker, worker_ids, soldier, soldier_ids, owner, larva } = await loadFixture(hatch_Fixture);
      expect(soldier_ids.length).to.be.greaterThan(1);
      await worker.build(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerBuild + 10]);
      await network.provider.send("evm_mine");
      const workerMissions = await microColonies.getUserMissions(owner.address, 2);
      await worker.claimBuilt(workerMissions[0]);
      const capacity = parseFloat((await microColonies.capacity(owner.address)).toString());
      const nested = parseFloat((await microColonies.nested(owner.address)).toString());
      expect(capacity - nested).to.be.greaterThan(3);
      const addr1_mock20 = mock20.connect(addr1);
      await addr1_mock20.approve(tournament.address, 1);
      const addr1_tournament = tournament.connect(addr1);
      await addr1_tournament.enterTournament("Address 1",);
      const addr1_larva = larva.connect(addr1);
      await addr1_larva.incubate(19, 0);
      const addr1_missions = await microColonies.getUserMissions(addr1.address, 1);
      expect(addr1_missions.length).to.equal(1);
      const addr2_mock20 = mock20.connect(addr2);
      await addr2_mock20.approve(tournament.address, 1);
      const addr2_tournament = tournament.connect(addr2);
      await addr2_tournament.enterTournament("Address 2",);
      const addr2_larva = larva.connect(addr2);
      await addr2_larva.incubate(19, 0);
      const feromon_pre = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      const larva_pre = parseFloat((await microColonies.getUserIds(owner.address, 1, false)).length.toString());
      expect(larva_pre).to.equal(0);
      await soldier.scout(3);
      const missions = await microColonies.getUserMissions(owner.address, 3);
      expect((await microColonies.getMissionIds(owner.address, 3, missions[0])).length).to.equal(3);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      const target = await soldier.reveal(missions[0]);
      expect(target).to.equal(addr1.address);
      await soldier.attack(missions[0]);
      const larva_after = parseFloat((await microColonies.getUserIds(owner.address, 1, false)).length.toString());
      expect(larva_after).to.be.greaterThan(larva_pre);
      const feromon_after = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      expect(feromon_after - feromon_pre).to.equal(3);
    });
    it("Should become zombie after 2 missions", async () => {
      feedAmount = 19;
      const { microColonies, tournament, mock20, addr1, addr2, worker, worker_ids, soldier, soldier_ids, owner, larva } = await loadFixture(hatch_Fixture);
      expect(soldier_ids.length).to.be.greaterThan(1);
      await worker.build(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerBuild + 10]);
      await network.provider.send("evm_mine");
      const workerMissions = await microColonies.getUserMissions(owner.address, 2);
      await worker.claimBuilt(workerMissions[0]);
      const capacity = parseFloat((await microColonies.capacity(owner.address)).toString());
      const nested = parseFloat((await microColonies.nested(owner.address)).toString());
      expect(capacity - nested).to.be.greaterThan(soldier_ids.length);
      const addr1_mock20 = mock20.connect(addr1);
      await addr1_mock20.approve(tournament.address, 1);
      const addr1_tournament = tournament.connect(addr1);
      await addr1_tournament.enterTournament("Address 1",);
      const addr1_larva = larva.connect(addr1);
      await addr1_larva.incubate(19, 0);
      const addr1_missions = await microColonies.getUserMissions(addr1.address, 1);
      expect(addr1_missions.length).to.equal(1);
      const addr2_mock20 = mock20.connect(addr2);
      await addr2_mock20.approve(tournament.address, 1);
      const addr2_tournament = tournament.connect(addr2);
      await addr2_tournament.enterTournament("Address 2",);
      const addr2_larva = larva.connect(addr2);
      await addr2_larva.incubate(19, 0);
      await soldier.scout(soldier_ids.length);
      let missions = await microColonies.getUserMissions(owner.address, 3);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      let target = await soldier.reveal(missions[0]);
      expect(target).to.equal(addr1.address || addr2.address);
      await soldier.retreat(missions[0]);
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(1);
      await soldier.scout(soldier_ids.length);
      missions = await microColonies.getUserMissions(owner.address, 3);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      target = await soldier.reveal(missions[0]);
      expect(target).to.equal(addr1.address || addr2.address);
      await soldier.retreat(missions[0]);
      expect(await microColonies.getUserIds(owner.address, 3, false)).to.not.include(soldier_ids[0]);
    });
    it("Should get harvested as zombie", async () => {
      feedAmount = 19;
      const { microColonies, tournament, mock20, addr1, addr2, worker, worker_ids, soldier, soldier_ids, owner, larva, zombie, zombie_ids } = await loadFixture(
        hatch_Fixture
      );
      expect(soldier_ids.length).to.be.greaterThan(1);
      await worker.build(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerBuild + 10]);
      await network.provider.send("evm_mine");
      const workerMissions = await microColonies.getUserMissions(owner.address, 2);
      await worker.claimBuilt(workerMissions[0]);
      const capacity = parseFloat((await microColonies.capacity(owner.address)).toString());
      const nested = parseFloat((await microColonies.nested(owner.address)).toString());
      expect(capacity - nested).to.be.greaterThan(soldier_ids.length);
      const addr1_mock20 = mock20.connect(addr1);
      await addr1_mock20.approve(tournament.address, 1);
      const addr1_tournament = tournament.connect(addr1);
      await addr1_tournament.enterTournament("Address 1",);
      const addr1_larva = larva.connect(addr1);
      await addr1_larva.incubate(19, 0);
      const addr1_missions = await microColonies.getUserMissions(addr1.address, 1);
      expect(addr1_missions.length).to.equal(1);
      const addr2_mock20 = mock20.connect(addr2);
      await addr2_mock20.approve(tournament.address, 1);
      const addr2_tournament = tournament.connect(addr2);
      await addr2_tournament.enterTournament("Address 2",);
      const addr2_larva = larva.connect(addr2);
      await addr2_larva.incubate(19, 0);
      await soldier.scout(soldier_ids.length);
      let missions = await microColonies.getUserMissions(owner.address, 3);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      let target = await soldier.reveal(missions[0]);
      expect(target).to.equal(addr1.address || addr2.address);
      await soldier.retreat(missions[0]);
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(1);
      await soldier.scout(soldier_ids.length);
      missions = await microColonies.getUserMissions(owner.address, 3);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      target = await soldier.reveal(missions[0]);
      expect(target).to.equal(addr1.address || addr2.address);
      await soldier.retreat(missions[0]);
      expect(await microColonies.getUserIds(owner.address, 3, false)).to.not.include(soldier_ids[0]);
      let zombies = await microColonies.getUserIds(owner.address, 6, true);
      await zombie.harvest(zombies.length);
      const zombieMissions = await microColonies.getUserMissions(owner.address, 6);
      await network.provider.send("evm_increaseTime", [epoch * zombieHarvest + 10]);
      await network.provider.send("evm_mine");
      const funghi_pre = parseFloat((await microColonies.funghiBalance(owner.address)).toString());
      await zombie.claimHarvested(zombieMissions[zombieMissions.length - 1]);
      const funghi_after = parseFloat((await microColonies.funghiBalance(owner.address)).toString());
      expect(funghi_after - funghi_pre).to.equal(zombies.length * harvestReward);
    });
  });
  describe("Princess Unit Tests", () => {
    it("Should mate on-season", async () => {
      const { owner, microColonies, princess, princess_ids } = await loadFixture(hatch_Fixture);
      expect(princess_ids.length).to.be.greaterThanOrEqual(1);
      const [start, end] = await princess.seasonDates();
      await time.increaseTo(parseFloat(start[1].toString()));
      await princess.mate(princess_ids.length);
      let missions = await microColonies.getUserMissions(owner.address, 5);
      await time.increaseTo(parseFloat(start[1].toString()) + epoch * 4 + 10);
      await princess.claimMated(missions[missions.length - 1]);
      const queens = await microColonies.getUserIds(owner.address, 0, false);
      expect(queens.length).to.be.greaterThanOrEqual(1);
    });
    it("Should mate off-season", async () => {
      const { owner, microColonies, princess, princess_ids } = await loadFixture(hatch_Fixture);
      expect(princess_ids.length).to.be.greaterThanOrEqual(1);
      const [start, end] = await princess.seasonDates();
      await time.increaseTo(parseFloat(start[1].toString()) - 1000);
      await princess.mate(princess_ids.length);
      let missions = await microColonies.getUserMissions(owner.address, 5);
      await time.increaseTo(parseFloat(start[1].toString()) + epoch * 4 + 10);
      await princess.claimMated(missions[missions.length - 1]);
      const queens = await microColonies.getUserIds(owner.address, 0, false);
      expect(queens.length).to.be.greaterThanOrEqual(1);
      const princesses = await microColonies.getUserIds(owner.address, 5, false);
      expect(princesses.length).to.equal(0);
    });
  });
  describe("Queen Unit Tests", () => {
    it("Should lay eggs ", async () => {
      feedAmount = 20;
      const { owner, microColonies, queen, queen_ids } = await loadFixture(hatch_Fixture);
      expect(queen_ids.length).to.equal(1);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.be.closeTo(80, 1);
      const now = Math.floor(Date.now() / 1000).toString();
      await time.increaseTo(parseFloat(now) + epoch * 1 + 100);
      let epochs = await queen.getQueenEpochs(queen_ids[0]);
      expect(epochs).to.equal(1);
      let timeToNext = await queen.getTimeToNext(queen_ids[0]);
      expect(timeToNext).not.to.equal(0);
      await queen.claimEggs(queen_ids[0]);
      let larvae = await microColonies.getUserIds(owner.address, 1, false);
      expect(larvae.length).to.equal(5);
      await time.increaseTo(parseFloat(now) + epoch * 5 + 100);
      await queen.claimEggs(queen_ids[0]);
      larvae = await microColonies.getUserIds(owner.address, 1, false);
      expect(larvae.length).to.equal(15);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.equal(0);
      epochs = await queen.getQueenEpochs(queen_ids[0]);
      expect(epochs).to.equal(5);
      timeToNext = await queen.getTimeToNext(queen_ids[0]);
      expect(timeToNext).to.equal(0);
    });
    it("Should feed and keep producing", async () => {
      feedAmount = 20;
      const { owner, microColonies, queen, queen_ids } = await loadFixture(hatch_Fixture);
      expect(queen_ids.length).to.equal(1);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.be.closeTo(80, 1);
      let now = Math.floor(Date.now() / 1000).toString();
      await time.increaseTo(parseFloat(now) + epoch * 6);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.equal(0);
      await queen.claimEggs(queen_ids[0]);
      const larvae = await microColonies.getUserIds(owner.address, 1, false);
      expect(larvae.length).to.equal(15);
      //feed
      await queen.feedQueen(queen_ids[0]);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.equal(100);
      await time.increaseTo(parseFloat(now) + epoch * 12);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.equal(0);
      await queen.claimEggs(queen_ids[0]);
    });
    it("Should upgrade and produce more", async () => {
      feedAmount = 20;
      const { owner, microColonies, queen, queen_ids } = await loadFixture(hatch_Fixture);
      expect(queen_ids.length).to.equal(1);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.be.closeTo(80, 1);
      let now = Math.floor(Date.now() / 1000).toString();
      await time.increaseTo(parseFloat(now) + epoch * 6);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.equal(0);
      await queen.queenUpgrade(queen_ids[0]);
      let larvae = await microColonies.getUserIds(owner.address, 1, false);
      expect(larvae.length).to.equal(15);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.equal(100);
      expect((await microColonies.q(queen_ids[0])).level).to.equal(2);
      await time.increaseTo(parseFloat(now) + epoch * 13);
      expect(await queen.getQueenEnergy(queen_ids[0])).to.equal(0);
      await queen.claimEggs(queen_ids[0]);
      larvae = await microColonies.getUserIds(owner.address, 1, false);
      expect(larvae.length).to.equal(43);
    });
  });
});
