// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
// const hre = require("hardhat");
// const { ethers } = require("hardhat");

const { BigNumber, utils } = require('ethers');
const master  = require('../test/wordleMaster');



async function main () {
  const NFT = await ethers.getContractFactory("ZKWordleNFT", {
    libraries: {
      NFTDescriptor: "0x8B42fF11cDeAa58AE5b3a3CD5f18EB278FdD353E",
    },
  });

  const nftAddress = "0x5a0CFE0D1A3Ee68c1D2254B408c529C2C8129960";
  const nft = await NFT.attach(nftAddress);
  const wordleAddress = '0x22f5887ae1bc1E941090CCf00356F897856102dE'
  const minterTx = await nft.setMinter(wordleAddress);
  await minterTx.wait();
  console.log('ok')

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
