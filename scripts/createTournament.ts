import { ethers } from "hardhat";

const factory = "0x7f43Aed6f5f870B67903439ddD51e00E3A96d878";
const dead = "0x0000000000000000000000000000000000000000"

async function main() {
  const TournamentFactory = await ethers.getContractFactory("TournamentFactory");
  const tournamentFactory = TournamentFactory.attach(factory);
  const now = (Math.floor(Date.now() / 1000) + 3600).toString();
  const tx = await tournamentFactory.createTournament("Mission Impossible", 0, dead, now, 20, 0, 2);
  const receipt = await tx.wait();
  console.log("Tx receipt:", receipt);
  const tournaments = await tournamentFactory.getTournaments();
  const tournamentAddr = tournaments[tournaments.length - 1];
  console.log("Tournament address -> ", tournamentAddr);
  const Tournament = await ethers.getContractFactory("Tournament");
  const tournament = Tournament.attach(tournamentAddr);
  const entertx = await tournament.enterTournament("Takezo");
  await entertx.wait();
  console.log("Entered.");
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
