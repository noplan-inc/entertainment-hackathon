// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
// const hre = require("hardhat");
// const { ethers } = require("hardhat");




async function main () {
  const ZKWordle = await ethers.getContractFactory("ZKWordle");
  const nft = "0xe7850330229ab5304a7Bb74b6af1e06BAAc55467";
  const zkWordle = await ZKWordle.deploy(nft);
  await zkWordle.deployed();

  const nonceTx = await zkWordle.setNonce();
  await nonceTx.wait();

  console.log("zkWordle deployed to:", zkWordle.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
