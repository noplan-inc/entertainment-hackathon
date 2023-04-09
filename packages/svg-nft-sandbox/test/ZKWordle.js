const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const {wodles} = require("./wordleMaster");

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
});
