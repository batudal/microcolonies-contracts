
import { ethers } from "hardhat";

async function main() {
  const Mock21 = await ethers.getContractFactory("Mock21");
  const mock21 = await Mock21.deploy();
  console.log("Mock21 -> ", mock21.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
