import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-tracer";
import "hardhat-gas-reporter";
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: true,
  },
  networks: {
    devm: {
      url: process.env.DEVM_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
    token: "MATIC",
    gasPrice: 80,
    gasPriceApi: "https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice",
    coinmarketcap: process.env.COINMARKETCAP,
  },
  // tracer: {
  //   nameTags: {
  //     "0x0B306BF915C4d645ff596e518fAf3F9669b97016": "Tournament",
  //   },
  // },
};

export default config;
