import { ethers } from "hardhat";
const tournamentAddr = "0xA272076c89914779aD643D73F01b33D8343110be";
const takezo = "0xfb1c2ff46962b452c1731d44f0789bfb3607e63f";

async function main() {
  const Tournament = await ethers.getContractFactory("Tournament");
  const tournament = Tournament.attach(tournamentAddr);
  const contracts = await tournament.contracts();
  const larvaAddr = contracts[2];
  console.log("Larva addr -> ", larvaAddr);
  const Larva = await ethers.getContractFactory("Larva");
  const larva = Larva.attach(larvaAddr);
  // const tx = await larva.incubate(20, 0);
  // await tx.wait();
  // console.log("Incubation started.");
  const microAddr = contracts[0];
  console.log("Micro addr -> ", microAddr);
  const Micro = await ethers.getContractFactory("MicroColonies");
  const micro = Micro.attach(microAddr);
  const missions = await micro.getUserMissions(takezo, 1);
  const tx = await larva.hatch(missions[0]);
  await tx.wait();
  console.log("Hatched.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
