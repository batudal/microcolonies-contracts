import { ethers, upgrades, network } from "hardhat";

const takezo = "0xfb1c2ff46962b452c1731d44f0789bfb3607e63f";
const factory = "0xe499A33a1EfCA10199622DFFDF89ade102E7ce98";
const mock20 = "0x49b4595E5CAcaE50aD83990Ec866AcA79Cf6d6D0";
const epoch = 120;

async function main() {
  const TournamentFactory = await ethers.getContractFactory("TournamentFactory");
  const tournamentFactory = TournamentFactory.attach(factory);
  const now = Math.floor(Date.now() / 1000).toString();
  const tx = await tournamentFactory.createTournament("My Second Tourney", [takezo], 0, mock20, epoch, now);
  await tx.wait();
  const tournamentAddr = (await tournamentFactory.getTournaments())[0];
  console.log("Tournament address -> ", tournamentAddr);
  const Tournament = await ethers.getContractFactory("Tournament");
  const tournament = Tournament.attach(tournamentAddr);
  await tournament.enterTournament("Takezo", 0);
  console.log("Entered.");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
