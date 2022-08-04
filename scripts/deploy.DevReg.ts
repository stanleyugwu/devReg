import { ethers, upgrades } from "hardhat";
import { DevReg__factory } from "../typechain-types/index";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const DEPLOYED_STRING_LIBRARY_ADDRESS =
    "0xD441D2B289D5783ebD05fb2D04726Cf7C8DB37f4";

  const DevReg = (await ethers.getContractFactory("DevReg", {
    libraries: { String: DEPLOYED_STRING_LIBRARY_ADDRESS },
  })) as DevReg__factory;
  let devReg = await upgrades.deployProxy(DevReg, {
    unsafeAllow: [
      "state-variable-immutable",
      "constructor",
      "external-library-linking",
    ],
  });

  devReg = await devReg.deployed();

  console.log("DevReg Address: " + devReg.address);
  return true;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
