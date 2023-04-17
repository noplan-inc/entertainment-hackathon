const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const {wordles} = require("./wordleMaster");
const {getWordDec, getWordHex, addressToUintArray} = require("./utils");
const fs = require('fs');
const v8 = require('v8');
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

    const LIB = await ethers.getContractFactory("NFTDescriptor");
    const lib = await LIB.deploy();

    const NFT = await ethers.getContractFactory("ZKWordleNFT", {
      libraries: {
        NFTDescriptor: lib.address,
      },
    });
    const nft = await NFT.deploy();


    const ZKWordle = await ethers.getContractFactory("ZKWordle");
    const zkWordle = await ZKWordle.deploy(nft.address);

    await nft.setMinter(zkWordle.address);


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

      const size = wordles.length;
      const randao = await zkWordle.getRandao();
      const index = randao.mod(size);
      const answer = wordles[index];
      const hashedAnswer = ethers.utils.sha256(ethers.utils.toUtf8Bytes(answer));

      await expect(zkWordle.createQuestion(
        hashedAnswer
      )).not.to.be.reverted;

      expect(await zkWordle.round()).to.equal(0);
      
    });
  });

  describe("answer", function() {
    it("should success", async function() {
      let { initialize } = await import("zokrates-js");

      const zokrates = await initialize();
      const { zkWordle, otherAccount } = await loadFixture(deployFixture);

      const size = wordles.length;
      const randao = await zkWordle.getRandao();
      const index = randao.mod(size);
      const _answer = 'shoos'

      // const _answer = wordles[index];
      const _hashedAnswer = ethers.utils.sha256(ethers.utils.toUtf8Bytes(_answer));

      await expect(zkWordle.createQuestion(
        _hashedAnswer
      )).not.to.be.reverted;


      let artifacts = null;
      if (!fs.existsSync('./test/answer/artifacts')) {
        artifacts = zokrates.compile(zkSource);
        const serializedArtifacts = v8.serialize(artifacts);
        fs.writeFileSync('./test/answer/artifacts', serializedArtifacts);
      } else {
        const rawArtifacts = fs.readFileSync('./test/answer/artifacts');
        artifacts = v8.deserialize(rawArtifacts);
      }

      const answer = getWordDec(_answer);
      const hashedAnswer = getWordHex(_answer);
      const address = addressToUintArray(otherAccount.address);

      console.log(`word: ${answer}, type: ${typeof answer}`);
      console.log(`expectedHash(dec chunked): ${hashedAnswer}, type: ${typeof hashedAnswer}`);
      console.log(`address: ${address}, type: ${typeof address}`);

      console.log(answer);
      console.log(hashedAnswer);
      console.log(address);


      const {witness, output} = zokrates.computeWitness(artifacts, [answer, hashedAnswer, address, address]);


      /* 
      普段は出力しない(コントラクトをちょっといじってるので変わってしまうため)
      // そらすえ神により、17ぐらいじゃねって言われて17で失敗したので、18にした
      const srs = zokrates.universalSetup(18);
      const key = zokrates.setupWithSrs(srs, artifacts.program);
      const pk = key.pk;
      // fs write
      fs.writeFileSync('./test/proving222.key', pk);
      const verifier = zokrates.exportSolidityVerifier(key.vk);
      fs.writeFileSync('./test/verifier.sol', verifier);
      */


      let key = null;
      if (!fs.existsSync('./test/answer/proving_raw.key') || !fs.existsSync('./test/answer/verifying.key')) {
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
        key = zokrates.setup(artifacts.program);
        fs.writeFileSync('./test/answer/proving_raw.key', key.pk);
        // vkを保存しておく
        fs.writeFileSync('./test/answer/verifying.key', JSON.stringify(key.vk));

        const verifier = zokrates.exportSolidityVerifier(key.vk);
        fs.writeFileSync('./test/answer/verifier.sol', verifier);
      } else {
        const pk = fs.readFileSync('./test/answer/proving_raw.key');
        const vk = JSON.parse(fs.readFileSync('./test/answer/verifying.key'));
        key = {pk, vk};
      }

      // console.log(new Uint8Array(vkey));
      // console.log(v8.deserialize(vkey));

      // throw Error('aa');

      // console.log(new Uint8Array(pkey))
      const result = zokrates.generateProof(artifacts.program, witness, key.pk);
      expect(zokrates.verify(key.vk, result)).to.be.true;

      const {a, b, c} = result.proof;

      // colorsという30個の1が入ってる配列を作る
      const colors = Array(30).fill(1);

      await expect(zkWordle.connect(otherAccount).answer([a,b,c], _answer, colors)).not.to.be.reverted;
    });
  });
});