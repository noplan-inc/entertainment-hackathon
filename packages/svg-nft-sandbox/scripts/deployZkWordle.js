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
  const nft = "0x5a0CFE0D1A3Ee68c1D2254B408c529C2C8129960";
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
