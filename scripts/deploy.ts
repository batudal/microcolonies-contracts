import { ethers, upgrades } from "hardhat";
const takezo = "0xfb1c2ff46962b452c1731d44f0789bfb3607e63f";

async function main() {
  const Mock20 = await ethers.getContractFactory("Mock20");
  const mock20 = await Mock20.deploy();
  console.log("Mock20 -> ", mock20.address);
  await mock20.mint(takezo, ethers.utils.parseEther("100"));
  // microcolonies deploy
  const MicroColonies = await ethers.getContractFactory("MicroColonies");
  const microColonies = await MicroColonies.deploy();
  await microColonies.deployed();
  console.log("Microcolonies -> ", microColonies.address);
  const init_microColonies = await microColonies.initialize("0", [takezo]);
  await init_microColonies.wait();
  // queen deploy
  const Queen = await ethers.getContractFactory("Queen");
  const queen = await Queen.deploy();
  await queen.deployed();
  console.log("Queen -> ", queen.address);
  const init_queen = await queen.initialize(microColonies.address);
  await init_queen.wait();
  // larva deploy
  const Larva = await ethers.getContractFactory("Larva");
  const larva = await Larva.deploy();
  await larva.deployed();
  console.log("Larva -> ", larva.address);
  const init_larva = await larva.initialize(microColonies.address);
  await init_larva.wait();
  // worker deploy
  const Worker = await ethers.getContractFactory("Worker");
  const worker = await Worker.deploy();
  await worker.deployed();
  console.log("Worker -> ", worker.address);
  const init_worker = await worker.initialize(microColonies.address);
  await init_worker.wait();
  // soldier deploy
  const Soldier = await ethers.getContractFactory("Soldier");
  const soldier = await Soldier.deploy();
  await soldier.deployed();
  console.log("Soldier -> ", soldier.address);
  const init_soldier = await soldier.initialize(microColonies.address);
  await init_soldier.wait();
  // deploy princess
  const Princess = await ethers.getContractFactory("Princess");
  const princess = await Princess.deploy();
  await princess.deployed();
  console.log("Princess -> ", princess.address);
  const init_princess = await princess.initialize(microColonies.address);
  await init_princess.wait();
  //deploy disaster
  const Disaster = await ethers.getContractFactory("Disaster");
  const disaster = await Disaster.deploy();
  await disaster.deployed();
  console.log("Disaster -> ", disaster.address);
  const init_disaster = await disaster.initialize(microColonies.address);
  await init_disaster.wait();

  const TournamentFactory = await ethers.getContractFactory("TournamentFactory");
  const tournamentFactory = await upgrades.deployProxy(TournamentFactory, [
    [microColonies.address, queen.address, larva.address, worker.address, soldier.address, princess.address, disaster.address],
  ]);
  await tournamentFactory.deployed();
  console.log("Tournament factory -> ", tournamentFactory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
