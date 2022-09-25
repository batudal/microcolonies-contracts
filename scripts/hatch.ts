import { ethers } from "hardhat";
const tournamentAddr = "0x96f99bCBB37Fa0ef5C615dE8Da23820696292b98";
const takezo = "0xfb1c2ff46962b452c1731d44f0789bfb3607e63f";
const epoch = 120;

async function main() {
  const Tournament = await ethers.getContractFactory("Tournament");
  const tournament = Tournament.attach(tournamentAddr);
  const contracts = await tournament.contracts();
  const larvaAddr = contracts[2];
  console.log("Trying incubation...");
  const Larva = await ethers.getContractFactory("Larva");
  const larva = Larva.attach(larvaAddr);
  const tx = await larva.incubate(20, 0);
  await tx.wait();
  console.log("Incubation started.");
  setTimeout(async () => {
    console.log("Trying hatching...");
    const microAddr = contracts[0];
    const Micro = await ethers.getContractFactory("MicroColonies");
    const micro = Micro.attach(microAddr);
    const missions = await micro.getUserMissions(takezo, 1);
    const tx = await larva.hatch(missions[0]);
    await tx.wait();
    console.log("Hatched.");
  }, 1000 * epoch);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
