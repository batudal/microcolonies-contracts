import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades, network } from "hardhat";
import hre from "hardhat";
import { TournamentFactory__factory } from "../typechain-types";
const takezo = "0xfB1C2FF46962B452C1731d44F0789bFb3607e63f";
const epoch = 21600;
let feedAmount = 0;
// schedule.workerFarm = 1;
// schedule.workerBuild = 5;
// schedule.conversion = 1;
// schedule.soldierRaid = 3;
// schedule.zombification = 5;
// schedule.zombieHarvest = 5;
// schedule.zombieGuard = 1;
// schedule.incubation = 1;
// schedule.queenPeriod = 1;
// schedule.lollipopDuration = 1;
// tariff.larvaPortion = 400;
// tariff.queenPortion = 240;
// tariff.queenUpgrade = 1000;
// tariff.conversion = 100;
// tariff.zombieHarvest = 400;
// tariff.buildReward = 5;

const farmReward = 80;
const workerBuild = 5;
const workerFarm = 1;
const buildReward = 5;
const conversionAmount = 10;
const conversionDuration = 1;
const soldierScout = 3;
const zombieHarvest = 5;
const harvestReward = 400;

describe("Tournament Tests", function () {
  async function deployFixture() {
    // deploy mock erc20 and mint some
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Mock20 = await ethers.getContractFactory("Mock20");
    const mock20 = await Mock20.deploy();
    await mock20.mint(owner.address, ethers.utils.parseEther("100"));
    // microcolonies deploy
    const MicroColonies = await ethers.getContractFactory("MicroColonies");
    const microColonies = await MicroColonies.deploy();
    await microColonies.deployed();
    const init_microColonies = await microColonies.initialize("0", [owner.address, addr1.address, addr2.address]);
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
    //deploy disaster
    const Disaster = await ethers.getContractFactory("Disaster");
    const disaster = await Disaster.deploy();
    await disaster.deployed();
    const init_disaster = await disaster.initialize(microColonies.address);
    await init_disaster.wait();

    // deploy tournamentFactory
    const TournamentFactory = await ethers.getContractFactory("TournamentFactory");
    const tournamentFactory = await upgrades.deployProxy(TournamentFactory, [
      [microColonies.address, queen.address, larva.address, worker.address, soldier.address, princess.address, disaster.address],
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
      Disaster,
      tournamentFactory,
    };
  }
  async function createFixture() {
    const { mock20, MicroColonies, Queen, Larva, Worker, Soldier, Princess, Disaster, tournamentFactory } = await loadFixture(deployFixture);
    const [owner, addr1, addr2] = await ethers.getSigners();
    const now = Math.floor(Date.now() / 1000).toString();
    await tournamentFactory.createTournament("Title", [owner.address, addr1.address, addr2.address], 0, mock20.address, epoch, now);
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
    const disaster = Disaster.attach(tournamentContracts.disaster);
    return {
      mock20,
      microColonies,
      queen,
      larva,
      worker,
      soldier,
      princess,
      disaster,
      tournament,
      owner,
      addr1,
      addr2,
    };
  }
  async function hatchFixture() {
    const { mock20, microColonies, queen, larva, worker, soldier, princess, disaster, tournament, owner, addr1, addr2 } = await loadFixture(createFixture);
    await tournament.enterTournament("takezo_pack(0)", 0);
    await larva.incubate(20, feedAmount);
    const missions = await microColonies.getUserMissions(owner.address, 1);
    await network.provider.send("evm_increaseTime", [epoch + 10]);
    await network.provider.send("evm_mine");
    await larva.hatch(missions[0]);
    const worker_ids = await microColonies.getUserIds(owner.address, 2, false);
    const soldier_ids = await microColonies.getUserIds(owner.address, 3, false);
    const male_ids = await microColonies.getUserIds(owner.address, 4, false);
    const princess_ids = await microColonies.getUserIds(owner.address, 5, false);
    // console.log(`Hatch outcome: ${worker_ids.length}W ${soldier_ids.length}S ${male_ids.length}M ${princess_ids.length}P`);
    return {
      mock20,
      microColonies,
      queen,
      larva,
      worker,
      soldier,
      princess,
      disaster,
      tournament,
      owner,
      addr1,
      addr2,
      worker_ids,
      soldier_ids,
      male_ids,
      princess_ids,
    };
  }

  describe("Tournament Unit Tests", () => {
    it("Should create a tournament with free entrance", async function () {
      const { tournamentFactory, mock20 } = await loadFixture(deployFixture);
      const [owner, addr1, addr2] = await ethers.getSigners();
      const now = Math.floor(Date.now() / 1000).toString();
      const epoch = 21600;
      await tournamentFactory.createTournament("Title", [owner.address, addr1.address, addr2.address], 0, mock20.address, epoch, now);
      const tournaments = await tournamentFactory.getTournaments();
      expect(tournaments.length).to.equal(1);
    });
    it("Should enter tournament with pack(0)", async function () {
      const { tournament, microColonies, owner } = await loadFixture(createFixture);
      await tournament.enterTournament("takezo_pack(0)", 0);
      const capacity = await microColonies.capacity(owner.address);
      expect(capacity).to.equal(20);
      const nested = await microColonies.nested(owner.address);
      expect(nested).to.equal(0);
      const all_larvae = await microColonies.getUserIds(owner.address, 1, false);
      expect(all_larvae.length).to.equal(20);
      expect(all_larvae[0]).to.equal(0);
      expect(all_larvae[19]).to.equal(19);
      const available_larvae = await microColonies.getUserIds(owner.address, 1, true);
      expect(available_larvae.length).to.equal(20);
      expect(available_larvae[0]).to.equal(0);
      expect(available_larvae[19]).to.equal(19);
    });
    it("Should enter tournament with pack(1)", async function () {
      const { tournament, microColonies, owner } = await loadFixture(createFixture);
      await tournament.enterTournament("takezo_pack(1)", 1);
      const capacity = await microColonies.capacity(owner.address);
      expect(capacity).to.equal(20);
      const nested = await microColonies.nested(owner.address);
      expect(nested).to.equal(1);
      const all_princesses = await microColonies.getUserIds(owner.address, 5, false);
      expect(all_princesses.length).to.equal(1);
      expect(all_princesses[0]).to.equal(0);
      const available_princesses = await microColonies.getUserIds(owner.address, 5, true);
      expect(available_princesses.length).to.equal(1);
      expect(available_princesses[0]).to.equal(0);
      const all_larvae = await microColonies.getUserIds(owner.address, 1, false);
      expect(all_larvae.length).to.equal(15);
      expect(all_larvae[0]).to.equal(0);
      expect(all_larvae[14]).to.equal(14);
      const available_larvae = await microColonies.getUserIds(owner.address, 1, true);
      expect(available_larvae.length).to.equal(15);
      expect(available_larvae[0]).to.equal(0);
      expect(available_larvae[14]).to.equal(14);
    });
    it("Should enter tournament with pack(2)", async function () {
      const { tournament, microColonies, owner } = await loadFixture(createFixture);
      await tournament.enterTournament("takezo_pack(1)", 2);
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
      expect(all_larvae.length).to.equal(10);
      expect(all_larvae[0]).to.equal(0);
      expect(all_larvae[9]).to.equal(9);
      const available_larvae = await microColonies.getUserIds(owner.address, 1, true);
      expect(available_larvae.length).to.equal(10);
      expect(available_larvae[0]).to.equal(0);
      expect(available_larvae[9]).to.equal(9);
    });
  });
  describe("Larva Unit Tests", () => {
    it("Should incubate", async () => {
      const { tournament, microColonies, larva, owner } = await loadFixture(createFixture);
      await tournament.enterTournament("takezo_pack(0)", 0);
      const feromon_pre = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      await larva.incubate(20, 0);
      const missions = await microColonies.getUserMissions(owner.address, 1);
      expect(missions.length).to.equal(1);
      const missionIds = await microColonies.getMissionIds(owner.address, 1, missions[0]);
      expect(missionIds.length).to.equal(20);
      const feromon_after = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      expect(feromon_after - feromon_pre).to.equal(missionIds.length);
    });
    it("Should hatch (0/20 fed)", async () => {
      const { tournament, microColonies, larva, owner } = await loadFixture(createFixture);
      await tournament.enterTournament("takezo_pack(0)", 0);
      await larva.incubate(20, 0);
      const missions = await microColonies.getUserMissions(owner.address, 1);
      expect(missions.length).to.equal(1);
      const missionIds = await microColonies.getMissionIds(owner.address, 1, missions[0]);
      expect(missionIds.length).to.equal(20);
      await network.provider.send("evm_increaseTime", [epoch + 10]);
      await network.provider.send("evm_mine");
      expect(await microColonies.nested(owner.address)).to.equal(0);
      await larva.hatch(missions[0]);
      expect(await microColonies.nested(owner.address)).to.equal(20);
    });
    it("Should hatch (10/20 fed)", async () => {
      const { tournament, microColonies, larva, owner } = await loadFixture(createFixture);
      await tournament.enterTournament("takezo_pack(0)", 0);
      expect(await microColonies.funghiBalance(owner.address)).to.equal("100000");
      await larva.incubate(20, 10);
      expect(await microColonies.funghiBalance(owner.address)).to.equal("96000");
      const missions = await microColonies.getUserMissions(owner.address, 1);
      expect(missions.length).to.equal(1);
      const missionIds = await microColonies.getMissionIds(owner.address, 1, missions[0]);
      expect(missionIds.length).to.equal(20);
      await network.provider.send("evm_increaseTime", [epoch + 10]);
      await network.provider.send("evm_mine");
      expect(await microColonies.nested(owner.address)).to.equal(0);
      await larva.hatch(missions[0]);
      expect(await microColonies.nested(owner.address)).to.equal(20);
    });
    it("Should hatch (20/20 fed)", async () => {
      const { tournament, microColonies, larva, owner } = await loadFixture(createFixture);
      await tournament.enterTournament("takezo_pack(0)", 0);
      expect(await microColonies.funghiBalance(owner.address)).to.equal("100000");
      await larva.incubate(20, 20);
      expect(await microColonies.funghiBalance(owner.address)).to.equal("92000");
      const missions = await microColonies.getUserMissions(owner.address, 1);
      expect(missions.length).to.equal(1);
      const missionIds = await microColonies.getMissionIds(owner.address, 1, missions[0]);
      expect(missionIds.length).to.equal(20);
      await network.provider.send("evm_increaseTime", [epoch + 10]);
      await network.provider.send("evm_mine");
      expect(await microColonies.nested(owner.address)).to.equal(0);
      await larva.hatch(missions[0]);
      expect(await microColonies.nested(owner.address)).to.equal(20);
    });
  });
  describe("Worker Unit Tests", () => {
    it("Should farm and pay rewards", async () => {
      feedAmount = 0;
      const { microColonies, worker, worker_ids, owner } = await loadFixture(hatchFixture);
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
      const { microColonies, worker, worker_ids, owner } = await loadFixture(hatchFixture);
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
      const { microColonies, worker, worker_ids, soldier_ids, owner } = await loadFixture(hatchFixture);
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
  });
  // zombie defence integration!
  describe("Soldier Unit Tests", () => {
    it("Should scout and retreat", async () => {
      feedAmount = 20;
      const { microColonies, tournament, addr1, addr2, worker, worker_ids, soldier, soldier_ids, owner, larva } = await loadFixture(hatchFixture);
      expect(soldier_ids.length).to.be.greaterThan(1);
      await worker.build(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerBuild + 10]);
      await network.provider.send("evm_mine");
      const workerMissions = await microColonies.getUserMissions(owner.address, 2);
      await worker.claimBuilt(workerMissions[0]);
      const capacity = parseFloat((await microColonies.capacity(owner.address)).toString());
      const nested = parseFloat((await microColonies.nested(owner.address)).toString());
      expect(capacity - nested).to.be.greaterThan(soldier_ids.length);
      const addr1_tournament = tournament.connect(addr1);
      await addr1_tournament.enterTournament("Address 1", 0);
      const addr1_larva = larva.connect(addr1);
      await addr1_larva.incubate(20, 0);
      const addr1_missions = await microColonies.getUserMissions(addr1.address, 1);
      expect(addr1_missions.length).to.equal(1);
      const addr2_tournament = tournament.connect(addr2);
      await addr2_tournament.enterTournament("Address 2", 0);
      const addr2_larva = larva.connect(addr2);
      await addr2_larva.incubate(20, 0);
      const feromon_pre = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      const larva_pre = parseFloat((await microColonies.getUserIds(owner.address, 1, false)).length.toString());
      expect(larva_pre).to.equal(0);
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(3);
      await soldier.scout(soldier_ids.length);
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(2);
      const missions = await microColonies.getUserMissions(owner.address, 3);
      expect((await microColonies.getMissionIds(owner.address, 3, missions[0])).length).to.equal(soldier_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      const target = await soldier.reveal(missions[0]);
      expect(target).to.equal(addr1.address);
      await soldier.retreat(missions[0]);
      const larva_after = parseFloat((await microColonies.getUserIds(owner.address, 1, false)).length.toString());
      expect(larva_after).to.equal(larva_pre);
      const feromon_after = parseFloat((await microColonies.feromonBalance(owner.address)).toString());
      expect(feromon_after - feromon_pre).to.equal(soldier_ids.length);
    });
    it("Should scout and attack a target", async () => {
      feedAmount = 20;
      const { microColonies, tournament, addr1, addr2, worker, worker_ids, soldier, soldier_ids, owner, larva } = await loadFixture(hatchFixture);
      expect(soldier_ids.length).to.be.greaterThan(1);
      await worker.build(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerBuild + 10]);
      await network.provider.send("evm_mine");
      const workerMissions = await microColonies.getUserMissions(owner.address, 2);
      await worker.claimBuilt(workerMissions[0]);
      const capacity = parseFloat((await microColonies.capacity(owner.address)).toString());
      const nested = parseFloat((await microColonies.nested(owner.address)).toString());
      expect(capacity - nested).to.be.greaterThan(3);
      const addr1_tournament = tournament.connect(addr1);
      await addr1_tournament.enterTournament("Address 1", 0);
      const addr1_larva = larva.connect(addr1);
      await addr1_larva.incubate(20, 0);
      const addr1_missions = await microColonies.getUserMissions(addr1.address, 1);
      expect(addr1_missions.length).to.equal(1);
      const addr2_tournament = tournament.connect(addr2);
      await addr2_tournament.enterTournament("Address 2", 0);
      const addr2_larva = larva.connect(addr2);
      await addr2_larva.incubate(20, 0);
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
    it("Should become zombie after 3 missions", async () => {
      feedAmount = 20;
      const { microColonies, tournament, addr1, addr2, worker, worker_ids, soldier, soldier_ids, owner, larva } = await loadFixture(hatchFixture);
      expect(soldier_ids.length).to.be.greaterThan(1);
      await worker.build(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerBuild + 10]);
      await network.provider.send("evm_mine");
      const workerMissions = await microColonies.getUserMissions(owner.address, 2);
      await worker.claimBuilt(workerMissions[0]);
      const capacity = parseFloat((await microColonies.capacity(owner.address)).toString());
      const nested = parseFloat((await microColonies.nested(owner.address)).toString());
      expect(capacity - nested).to.be.greaterThan(soldier_ids.length);
      const addr1_tournament = tournament.connect(addr1);
      await addr1_tournament.enterTournament("Address 1", 0);
      const addr1_larva = larva.connect(addr1);
      await addr1_larva.incubate(20, 0);
      const addr1_missions = await microColonies.getUserMissions(addr1.address, 1);
      expect(addr1_missions.length).to.equal(1);
      const addr2_tournament = tournament.connect(addr2);
      await addr2_tournament.enterTournament("Address 2", 0);
      const addr2_larva = larva.connect(addr2);
      await addr2_larva.incubate(20, 0);
      await soldier.scout(soldier_ids.length);
      let missions = await microColonies.getUserMissions(owner.address, 3);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      let target = await soldier.reveal(missions[0]);
      expect(target).to.equal(addr1.address || addr2.address);
      await soldier.retreat(missions[0]);
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(2);
      await soldier.scout(soldier_ids.length);
      missions = await microColonies.getUserMissions(owner.address, 3);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      target = await soldier.reveal(missions[0]);
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
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(0);
    });
    it("Should get harvested as zombie", async () => {
      feedAmount = 20;
      const { microColonies, tournament, addr1, addr2, worker, worker_ids, soldier, soldier_ids, owner, larva } = await loadFixture(hatchFixture);
      expect(soldier_ids.length).to.be.greaterThan(1);
      await worker.build(worker_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * workerBuild + 10]);
      await network.provider.send("evm_mine");
      const workerMissions = await microColonies.getUserMissions(owner.address, 2);
      await worker.claimBuilt(workerMissions[0]);
      const capacity = parseFloat((await microColonies.capacity(owner.address)).toString());
      const nested = parseFloat((await microColonies.nested(owner.address)).toString());
      expect(capacity - nested).to.be.greaterThan(soldier_ids.length);
      const addr1_tournament = tournament.connect(addr1);
      await addr1_tournament.enterTournament("Address 1", 0);
      const addr1_larva = larva.connect(addr1);
      await addr1_larva.incubate(20, 0);
      const addr1_missions = await microColonies.getUserMissions(addr1.address, 1);
      expect(addr1_missions.length).to.equal(1);
      const addr2_tournament = tournament.connect(addr2);
      await addr2_tournament.enterTournament("Address 2", 0);
      const addr2_larva = larva.connect(addr2);
      await addr2_larva.incubate(20, 0);
      await soldier.scout(soldier_ids.length);
      let missions = await microColonies.getUserMissions(owner.address, 3);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      let target = await soldier.reveal(missions[0]);
      expect(target).to.equal(addr1.address || addr2.address);
      await soldier.retreat(missions[0]);
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(2);
      await soldier.scout(soldier_ids.length);
      missions = await microColonies.getUserMissions(owner.address, 3);
      await network.provider.send("evm_increaseTime", [epoch * soldierScout + 10]);
      await network.provider.send("evm_mine");
      target = await soldier.reveal(missions[0]);
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
      expect((await microColonies.s(soldier_ids[0])).hp).to.equal(0);
      await soldier.harvest(soldier_ids.length);
      await network.provider.send("evm_increaseTime", [epoch * zombieHarvest + 10]);
      await network.provider.send("evm_mine");
      missions = await microColonies.getUserMissions(owner.address, 3);
      const funghi_pre = parseFloat((await microColonies.funghiBalance(owner.address)).toString());
      await soldier.claimHarvested(missions[missions.length - 1]);
      const funghi_after = parseFloat((await microColonies.funghiBalance(owner.address)).toString());
      expect(funghi_after - funghi_pre).to.equal(soldier_ids.length * harvestReward);
    });
  });
});
