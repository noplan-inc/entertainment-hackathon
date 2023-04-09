// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
// const hre = require("hardhat");
// const { ethers } = require("hardhat");




async function main () {
  // const DynamicImageNFT = await ethers.getContractFactory("DynamicImageNFT");
  // const dynamicImageNFT = await DynamicImageNFT.deploy();
  // await dynamicImageNFT.deployed();
  // console.log("DynamicImageNFT deployed to:", dynamicImageNFT.address);
  const Nonce = await ethers.getContractFactory("Nonce");
  console.log(await Nonce.interface.encodeDeploy([]));
  nonce = await Nonce.deploy();
  await nonce.deployed();
  console.log("Nonce deployed to:", nonce.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
