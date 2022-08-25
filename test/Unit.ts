import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

const takezo = "0xfB1C2FF46962B452C1731d44F0789bFb3607e63f";

describe("Tournament Unit Tests", function () {
  async function deployFixture() {
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
      tournamentFactory,
      queen,
      larva,
      worker,
      soldier,
      princess,
      disaster,
    };
  }

  describe("Free Tournament Test", function () {
    it("Should create tournament", async function () {
      const { tournamentFactory } = await loadFixture(deployFixture);
      const [owner, addr1, addr2] = await ethers.getSigners();
      const now = Math.floor(Date.now() / 1000).toString();
      const epoch = 21600;
      await tournamentFactory.createTournament("Title", [owner.address, addr1.address, addr2.address], 0, takezo, epoch, now);
      const tournaments = await tournamentFactory.getTournaments();
      expect(tournaments.length).to.equal(1);
    });
  });

  // describe("", function () {
  //   describe("", function () {
  //     it("", async function () {});
  //   });
  // });
});
