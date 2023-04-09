const args = process.argv.slice(2)[0];

console.log(`word: ${[...args].map(c => c.charCodeAt(0)).join(' ')}`);

function splitByChunk(str, size) {
  const numChunks = Math.ceil(str.length / size)
  const chunks = new Array(numChunks)
  for (let i=0, x=0; i < numChunks; ++i, x += size) {
    chunks[i] = str.substr(x, size)
  }
  return chunks
}

const crypto = require('crypto');
const hex = crypto.createHash('sha256').update(Buffer.from(args)).digest('hex');
const chunked = splitByChunk(hex, 8).map(e => `0x${e}`)
// hexをdecに変換してconsole.log
console.log(`expectedHash(dec chunked): ${chunked.map(e => parseInt(e, 16)).join(' ')}`);


