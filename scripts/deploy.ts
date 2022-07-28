import { ethers } from "hardhat";
import { DevReg__factory, String__factory } from "../typechain-types/index";

async function main() {
  const String = (await ethers.getContractFactory("String")) as String__factory;
  const stringLib = await (await String.deploy()).deployed();

  const DegReg = (await ethers.getContractFactory("DevReg", {
    libraries: { String: stringLib.address },
  })) as DevReg__factory;
  const devreg = await DegReg.deploy();

  await devreg.deployed();

  await devreg.functions.register(
    "devvie",
    "web3 developer",
    "Cool",
    true,
    "github.com/stanleyugwu",
    "github.com/stanleyugwu.png"
  );
  console.log(await devreg.functions.namesByAddress((await ethers.getSigners())[0].address));
  console.log(await devreg.functions.developers("devvie"))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
