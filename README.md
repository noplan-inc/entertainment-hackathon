# entertainment-hackathon

https://backend.serinuntius.workers.dev/game

**ZKWordle**

## 概要

フルオンチェーンの Wordle です。Wordle は 5 文字の単語をヒントを得ながら当てるゲームです。ZKP を使って、回答を明かすことなく、回答を知っていることを証明します。

LIVE DEMO

https://www.youtube.com/watch?v=fhSL8YJOwsM

## アプリケーションの起動方法

```bash
cd packages/backend
```

```bash
cp .dev.vars.example .dev.vars
```

```bash
yarn install --frozen-lockfile
```

```bash
yarn dev
```

`http://127.0.0.1:8788/game` へアクセス。

## デプロイ、ミンター設定

```bash
// NFTのデプロイ
yarn hardhat run --network goerli scripts/deployZkWordleNFT.js

// ゲームコントラクトのデプロイ
yarn hardhat run --network goerli scripts/deployZkWordle.js

// ミンターをセット
yarn hardhat run --network goerli scripts/setMinter.js
```

## 作問のための設定
```bash
// 作問
yarn hardhat run --network goerli scripts/createQuestion.js
```

## About

フルオンチェーンの Wordle です。Wordle は 5 文字の単語をヒントを得ながら当てるゲームです。ZKP を使って、回答を明かすことなく、回答を知っていることを証明します。
最速で正解するとかっこいいフルオンチェーンの NFT を取得することができます。

## Resolved technical issues

・ZKP の回路がデカすぎて、コンパイルだけでめちゃくちゃ時間がかかった
・最新技術すぎて How to がない

## 使用した技術

・Zokrates(ZKP): ZKP の回路の開発設計やテスト、Verify のためのコントラクトの生成

・Cloudflare Workes: CDN を利用しエッジでヒント API を返すことで、全世界で共通のレスポンスタイムになるように

・Superflare: Wokers 用のフレームワーク

・Remix: React のフレームワーク

## What we learned

・ZKP のノウハウ（テスト高速化、public/private input の使い分け、solidity の変数の変換、回路開発、回路をコンパクトにする方法）

・Superflare や Wokers 周り

## Next Actions

・Hint ZKP 有効化

・他所のチェーンでも動くように、drand と Lit で乱数オラクル作成

・作問自動化 Bot

## deploy した Contract

- https://testnets.opensea.io/ja/collection/zkwordlenft-1

- [lib](https://goerli.etherscan.io/address/0x54cF2B9f899202D32B773edE959894C3126ec1fd)

- [zkWordleNFT](https://goerli.etherscan.io/address/0xe7850330229ab5304a7Bb74b6af1e06BAAc55467)

- [zkWordle](https://goerli.etherscan.io/address/0xEF7AaeCE5d11e0BE9a3065a67bD8Ede62F8a783d)
