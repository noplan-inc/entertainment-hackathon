const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
const { BigNumber } = require("ethers");

  describe("Nonce", function () {
    const words = ["shoos",
    "pooks",
    "huger",
    "totes",
    "glial",
    "atigi",
    "mirth",
    "loans",
    "fagin",
    "phpht",
    "china",
    "toter",
  ];

    // Nonceのコントラクトをデプロイする
    async function deployNonceFixture() {
      const [owner, otherAccount] = await ethers.getSigners();
      const Nonce = await ethers.getContractFactory("Nonce");
      const nonce = await Nonce.deploy();
      return { nonce, owner, otherAccount };
    }

    describe("createNonceMappings", function () {
        it("Should return the right nonce array", async function () {
            let todayWords = [];
            const { nonce, owner } = await loadFixture(deployNonceFixture);
            const _nonce = await nonce.getNonce();
            console.log("_nonce");
            console.log(_nonce);
            // 1日のゲーム回数？
            let gameCount = 6;
            let wordsLength = BigNumber.from(words.length - 1);
            for(let i = 0; i < gameCount; i++) {
                let index = _nonce.mod(wordsLength).toNumber();
                todayWords.push(words[index]);
            }
            // これだと全部同じ単語になる
            console.log(todayWords);
        });
    });

  });