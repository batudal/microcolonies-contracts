import { ethers } from "hardhat";
const tournamentAddr = "0xffeF10Bcef6dc79748Ae14Edb7E73b10d5e3418F";
const takezo = "0xfb1c2ff46962b452c1731d44f0789bfb3607e63f";

async function main() {
  const Tournament = await ethers.getContractFactory("Tournament");
  const tournament = Tournament.attach(tournamentAddr);
  const contracts = await tournament.contracts();
  const microAddr = contracts[0];
  console.log("Micro addr -> ", microAddr);
  const Micro = await ethers.getContractFactory("MicroColonies");
  const micro = Micro.attach(microAddr);
  const ids = await micro.getUserIds(takezo, 0, false);
  console.log("IDS:", ids);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
