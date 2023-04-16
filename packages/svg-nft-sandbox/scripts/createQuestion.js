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
  const ZKWordle = await ethers.getContractFactory("ZKWordle");
  const address = "0x571590541A10a1Aec895F16E5f6601B4Eec7eb35";
  const zkWordle = await ZKWordle.attach(address);
  const nonceTx = await zkWordle.setNonce();
  await nonceTx.wait();
  const nonce = await zkWordle.getLatestNonce();
  console.log(nonce);

  console.log(master);
  const {wordles} = master;
  const size = wordles.length;
  const index = nonce.mod(size);
  console.log(index);
  const answer = wordles[index];
  console.log(answer);

  const hash = utils.sha256(utils.toUtf8Bytes(answer));

  // console.log(hash);

  const questionTx = await zkWordle.createQuestion(hash);
  await questionTx.wait();
  console.log('ok');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
