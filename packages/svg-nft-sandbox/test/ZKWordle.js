const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const {wodles} = require("./wordleMaster");
const {getWordDec, getWordHex, addressToUintArray} = require("./utils");
const fs = require('fs');

const zkSource = `
import "hashes/sha256/sha256Padded";

def main(private u8[5] word, u32[8] expectedHash,private  u32[8] addressUint, u32[8] pubAddressUint) -> bool {
    u32[8] hash = sha256Padded(word);

    assert(hash == expectedHash);
    assert(addressUint == pubAddressUint);
    return true;
}
`;


describe("ZKWordle", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const ZKWordle = await ethers.getContractFactory("ZKWordle");
    const zkWordle = await ZKWordle.deploy();

    return { zkWordle, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should success", async function () {
      const { zkWordle } = await loadFixture(deployFixture);

      expect(await zkWordle.round()).to.equal(0);
    });
  });

  describe("Randao", function () {
    it("Should success", async function () {
      const { zkWordle } = await loadFixture(deployFixture);

      const randao = await zkWordle.getRandao();
      // 110809542029779650567079838414844525958699392492796959957735648389144806727954
      expect(randao).not.to.equal(0);
    });
  });

  describe("createQuestion", function () {
    it("Should success", async function () {
      const { zkWordle } = await loadFixture(deployFixture);

      const size = wodles.length;
      const randao = await zkWordle.getRandao();
      const index = randao.mod(size);
      const answer = wodles[index];
      const hashedAnswer = ethers.utils.sha256(ethers.utils.toUtf8Bytes(answer));

      await expect(zkWordle.createQuestion(
        hashedAnswer
      )).not.to.be.reverted;

      expect(await zkWordle.round()).to.equal(1);
      
    });
  });

  describe("answer", function() {
    it("should success", async function() {
      let { initialize } = await import("zokrates-js");

      const zokrates = (await initialize()).withOptions({
        curve: "bn128",
        scheme: "g16",
        backend: "ark"
      });
      const { zkWordle, otherAccount } = await loadFixture(deployFixture);

      const size = wodles.length;
      const randao = await zkWordle.getRandao();
      const index = randao.mod(size);
      const _answer = wodles[index];
      const _hashedAnswer = ethers.utils.sha256(ethers.utils.toUtf8Bytes(_answer));

      await expect(zkWordle.createQuestion(
        _hashedAnswer
      )).not.to.be.reverted;

      const artifacts = zokrates.compile(zkSource);

      const answer = getWordDec(_answer);
      const hashedAnswer = getWordHex(_answer);
      const address = addressToUintArray(otherAccount.address);

      console.log(`word: ${answer}, type: ${typeof answer}`);
      console.log(`expectedHash(dec chunked): ${hashedAnswer}, type: ${typeof hashedAnswer}`);
      console.log(`address: ${address}, type: ${typeof address}`);

      const {witness, output} = zokrates.computeWitness(artifacts, [answer, hashedAnswer, address, address]);

      const key = fs.readFileSync('./test/proving.key');

      const {proof}=  zokrates.generateProof(artifacts.program,witness, key);
      console.log(`proof: ${proof}, type: ${typeof proof}, \n ${JSON.stringify(proof)}}`);
      // console.log(JSON.stringify(keypair));
      const {a, b, c} = proof;

      await expect(zkWordle.answer([a,b,c])).not.to.be.reverted;
    });
  });
});