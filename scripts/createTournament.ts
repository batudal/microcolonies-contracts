import { ethers } from "hardhat";

const takezo = "0xfb1c2ff46962b452c1731d44f0789bfb3607e63f";
const factory = "0x0685BBc47c265D550b1fBa9dB9A903b0dA661034";
const mock20 = "0x2C64Cc91b9fBA1c062b6dB8000dF0D381837eDa2";
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
  const entertx = await tournament.enterTournament("Takezo", 2);
  await entertx.wait();
  console.log("Entered.");
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
