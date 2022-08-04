import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import * as dotenv from "dotenv";
dotenv.config();

const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY!;

const config: HardhatUserConfig = {
  solidity: "0.8.15",
  networks: {
    goerli: {
      url: `https://rpc.goerli.mudit.blog/`,
      accounts: [GOERLI_PRIVATE_KEY],
    },
  },
};

export default config;
