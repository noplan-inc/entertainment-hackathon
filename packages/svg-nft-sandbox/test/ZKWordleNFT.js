const {
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { BigNumber } = require("ethers");

describe("ZKWordleNFT", function () {
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

    return { nft, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should success", async function () {
      const { nft } = await loadFixture(deployFixture);

      expect(await nft.name()).to.equal("ZKWordleNFT");
    });
  });

  describe("tokenURI", function () {
    it("Should success", async function () {
      const { nft, owner } = await loadFixture(deployFixture);

      const tokenId = BigNumber.from(1);
      const black = BigNumber.from(1);
      const yellow = BigNumber.from(2);
      const green = BigNumber.from(3);
      const word = "stock";
      const nonce = BigNumber.from(142344444);

      const colors = [
        [black, yellow, black, black, yellow],
        [black, yellow, black, black, black],
        [black, black, green, black, yellow],
        [black, black, green, black, yellow],
        [green, black, black, green, black],
        [green, green, green, green, green]
      ];
      // colorsをフラット化
      const colorsFlat = colors.flat();
      await nft.mint(owner.address, tokenId, word, nonce, colorsFlat);
      const tokenURI = await nft.tokenURI(tokenId);
      console.log(tokenURI);
    });
  });
});
