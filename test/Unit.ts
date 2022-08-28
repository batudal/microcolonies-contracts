import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades, network } from "hardhat";

const takezo = "0xfB1C2FF46962B452C1731d44F0789bFb3607e63f";
const epoch = 21600;

describe("Tournament Tests", function () {
  async function deployFixture() {
    // deploy mock erc20 and mint some
    const [owner] = await ethers.getSigners();
    const Mock20 = await ethers.getContractFactory("Mock20");
    const mock20 = await Mock20.deploy();
    await mock20.mint(owner.address, ethers.utils.parseEther("100"));
    // microcolonies deploy
    const MicroColonies = await ethers.getContractFactory("MicroColonies");
    const microColonies = await MicroColonies.deploy();
    await microColonies.deployed();
    const init_microColonies = await microColonies.initialize("0");
    await init_microColonies.wait();
    // queen deploy
    const Queen = await ethers.getContractFactory("Queen");
    const queen = await Queen.deploy();
    await queen.deployed();
    const init_queen = await queen.initialize(takezo);
    await init_queen.wait();
    // larva deploy
    const Larva = await ethers.getContractFactory("Larva");
    const larva = await Larva.deploy();
    await larva.deployed();
    const init_larva = await larva.initialize(takezo);
    await init_larva.wait();
    // worker deploy
    const Worker = await ethers.getContractFactory("Worker");
    const worker = await Worker.deploy();
    await worker.deployed();
    const init_worker = await worker.initialize(takezo);
    await init_worker.wait();
    // soldier deploy
    const Soldier = await ethers.getContractFactory("Soldier");
    const soldier = await Soldier.deploy();
    await soldier.deployed();
    const init_soldier = await soldier.initialize(takezo);
    await init_soldier.wait();
    // deploy princess
    const Princess = await ethers.getContractFactory("Princess");
    const princess = await Princess.deploy();
    await princess.deployed();
    const init_princess = await princess.initialize(takezo);
    await init_princess.wait();
    //deploy disaster
    const Disaster = await ethers.getContractFactory("Disaster");
    const disaster = await Disaster.deploy();
    await disaster.deployed();
    const init_disaster = await disaster.initialize(takezo);
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

  describe("Tournament Unit Tests", function () {
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
  describe("Larva Unit Tests", function () {
    it("Should deploy incubate mission (0/20 fed)", async () => {
      const { tournament, microColonies, larva, owner } = await loadFixture(createFixture);
      await tournament.enterTournament("takezo_pack(0)", 0);
      await larva.incubate(20, 0);
      const missions = await microColonies.getUserMissions(owner.address, 1);
      expect(missions.length).to.equal(1);
      const missionIds = await microColonies.getMissionIds(owner.address, 1, missions[0]);
      expect(missionIds.length).to.equal(20);
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
});
