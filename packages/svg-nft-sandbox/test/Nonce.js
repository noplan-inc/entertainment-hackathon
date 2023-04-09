const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { expect } = require("chai");
const { BigNumber, Contract } = require("ethers");
const { ethers, helpers } = require("hardhat");

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
        beforeEach(async function () {
            const {nonce, owner, otherAccount} = await loadFixture(deployNonceFixture);
            this.nonce = nonce;
            this.owner = owner;
            this.otherAccount = otherAccount;
        });
        it("Should create the right nonces", async function () {
            let nonces = [];
            for (let i = 1; i < 11; i++) {
                // 何回めのゲームか
                let round = i
                // そのゲームのnonceをセット
                await this.nonce.setNonce(round);
                // そのゲームのnonceを取得
                _nonce = await this.nonce.getNonce(round);
                // nonceを配列に入れる
                nonces.push(_nonce);
                // 時間進める
                ethers.provider.send("evm_increaseTime", [384]); // 約384秒(1エポック)以上にする必要ある 12秒(ブロック生成時間) * 32ブロック
            }
            expect(new Set(nonces).size === nonces.length).to.equal(true);
        });
        it("Should create the right indices", async function () {
            let todayWords = [];
            
            let wordleSize = BigNumber.from(words.length);
            // ゲームが10回あるとする
            for (let i = 1; i < 11; i++) {
                // 何回めのゲームか
                let round = i
                // そのゲームのnonceをセット
                await this.nonce.setNonce(round);
                // そのゲームのnonceを取得
                _nonce = await this.nonce.getNonce(round);
                // そのゲームのnonceをwordsのindexに変換
                todayWords.push(words[_nonce % wordleSize]);
                // 時間進める
                ethers.provider.send("evm_increaseTime", [384]); // 約384秒(1エポック)以上にする必要ある 12秒(ブロック生成時間) * 32ブロック
            }
            expect(todayWords.length).to.equal(10);
        });
    });

  });