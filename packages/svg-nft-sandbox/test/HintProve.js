const { expect } = require("chai");

const fs = require('fs');
const v8 = require('v8');
const msgpack = require('@msgpack/msgpack');

const zkSource = fs.readFileSync('../zkp/wordChecker/wordChecker.zok', 'utf-8');

describe("HintProve", function () {
  describe("prove", function() {
    it.only("should success", async function() {
      let { initialize } = await import("zokrates-js");

      const zokrates = await initialize();


      let artifacts = null;
      if (!fs.existsSync('./test/hint/wordChecker-artifacts')) {
        artifacts = zokrates.compile(zkSource);
        const serializedArtifacts = msgpack.encode(artifacts);
        fs.writeFileSync('./test/hint/wordChecker-artifacts', serializedArtifacts);
      } else {
        const rawArtifacts = fs.readFileSync('./test/hint/wordChecker-artifacts');
        artifacts = msgpack.decode(rawArtifacts);
      }

      console.log('before computeWitness');
      const word = 'shako';
      // TextEncoderを使うと、文字列をUint8Arrayに変換できる
      const encoded = new TextEncoder().encode(word);
      const params = encoded.map(e => e.toString()).toString();
      console.log(params);
      console.log(artifacts);
      console.log(artifacts.program.length);
      const {witness, output} = zokrates.computeWitness(artifacts, [params.split(',')]);
      console.log('after computeWitness');

      let key = null;
      if (!fs.existsSync('./test/hint/proving.key') || !fs.existsSync('./test/hint/verifying.key')) {
        key = zokrates.setup(artifacts.program);
        fs.writeFileSync('./test/hint/proving.key', key.pk);
        // vkを保存しておく
        fs.writeFileSync('./test/hint/verifying.key', msgpack.encode(key.vk));
      } else {
        const pk = fs.readFileSync('./test/hint/proving.key');
        const vk = msgpack.decode(fs.readFileSync('./test/hint/verifying.key'));
        key = {pk, vk};
      }
      console.log('generateProof');

      const proof = zokrates.generateProof(artifacts.program, witness, key.pk);
      console.log('generateProof done');

      expect(zokrates.verify(key.vk, proof)).to.be.true;
    });
  });
});
