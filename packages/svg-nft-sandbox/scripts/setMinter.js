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
      NFTDescriptor: "0xC4b8d3429F5E18604693155d0D30Da11aE1cE747",
    },
  });

  const nftAddress = "0xC224bb146B3c5C2498C67794ae0e746C27Ef862c";
  const nft = await NFT.attach(nftAddress);
  const wordleAddress = '0x7C372a3E9c275632cF10b2095746e55833Ea5407'
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
