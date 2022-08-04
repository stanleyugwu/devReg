import { ethers, upgrades } from "hardhat";
import { String__factory } from "../typechain-types/index";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const String = (await ethers.getContractFactory("String")) as String__factory;
  const string = await upgrades.deployProxy(String);

  const stringLib = await string.deployed();

  console.log("String Address: " + stringLib.address);
  return true;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
