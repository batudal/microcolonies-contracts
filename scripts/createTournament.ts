import { ethers } from "hardhat";

const takezo = "0xfb1c2ff46962b452c1731d44f0789bfb3607e63f";
const factory = "0xDd40FB77Ee1eda65AdFd09d2Bc3696b70F455706";
const mock20 = "0x18C6B883f3dEFe834f6929D6EcbD6e9F077CF49F";
const epoch = 120;

async function main() {
  const TournamentFactory = await ethers.getContractFactory("TournamentFactory");
  const tournamentFactory = TournamentFactory.attach(factory);
  const now = Math.floor(Date.now() / 1000).toString();
  const tx = await tournamentFactory.createTournament("My Tourney", [takezo], 0, mock20, epoch, now);
  await tx.wait();
  const tournaments = await tournamentFactory.getTournaments();
  const tournamentAddr = tournaments[tournaments.length - 1];
  console.log("Tournament address -> ", tournamentAddr);
  const Tournament = await ethers.getContractFactory("Tournament");
  const tournament = Tournament.attach(tournamentAddr);
  await tournament.enterTournament("Takezo", 0);
  console.log("Entered.");
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
