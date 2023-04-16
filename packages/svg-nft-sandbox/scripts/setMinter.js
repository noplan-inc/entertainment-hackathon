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
      NFTDescriptor: "0x54cF2B9f899202D32B773edE959894C3126ec1fd",
    },
  });

  const nftAddress = "0xe7850330229ab5304a7Bb74b6af1e06BAAc55467";
  const nft = await NFT.attach(nftAddress);
  const wordleAddress = '0xEF7AaeCE5d11e0BE9a3065a67bD8Ede62F8a783d'
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
