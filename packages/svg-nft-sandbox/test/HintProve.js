const { expect } = require("chai");

const fs = require('fs');
const v8 = require('v8');

const zkSource = fs.readFileSync('../zkp/wordChecker/wordChecker.zok', 'utf-8');

describe("HintProve", function () {
  describe("prove", function() {
    it.only("should success", async function() {
      let { initialize } = await import("zokrates-js");

      const zokrates = await initialize();


      let artifacts = null;
      if (!fs.existsSync('./test/wordChecker-artifacts')) {
        artifacts = zokrates.compile(zkSource);
        const serializedArtifacts = v8.serialize(artifacts);
        fs.writeFileSync('./test/wordChecker-artifacts', serializedArtifacts);
      } else {
        const rawArtifacts = fs.readFileSync('./test/wordChecker-artifacts');
        artifacts = v8.deserialize(rawArtifacts);
      }

      console.log('before computeWitness');
      const word = 'shako';
      // TextEncoderを使うと、文字列をUint8Arrayに変換できる
      const encoded = new TextEncoder().encode(word);
      const params = encoded.map(e => e.toString()).toString();
      console.log(params);
      const {witness, output} = zokrates.computeWitness(artifacts, [params.split(',')]);
      console.log('after computeWitness');

      let key = null;
      if (!fs.existsSync('./test/proving.key') || !fs.existsSync('./test/verifying.key')) {
        key = zokrates.setup(artifacts.program);
        fs.writeFileSync('./test/proving.key', v8.serialize(key.pk));
        // vkを保存しておく
        fs.writeFileSync('./test/verifying.key', v8.serialize(key.vk));
      } else {
        const pk = v8.deserialize(fs.readFileSync('./test/proving.key'));
        const vk = v8.deserialize(fs.readFileSync('./test/verifying.key'));
        key = {pk, vk};
      }
      console.log('generateProof');

      const proof = zokrates.generateProof(artifacts.program, witness, key.pk);
      console.log('generateProof done');

      expect(zokrates.verify(key.vk, proof)).to.be.true;
    });
  });
});
