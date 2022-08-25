import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-tracer";

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: true,
  },
  // tracer: {
  //   nameTags: {
  //     "0x0B306BF915C4d645ff596e518fAf3F9669b97016": "Tournament",
  //   },
  // },
};

export default config;
