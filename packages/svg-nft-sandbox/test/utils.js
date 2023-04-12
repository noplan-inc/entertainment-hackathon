const crypto = require('crypto');

const splitByChunk = (str, size) => {
    const numChunks = Math.ceil(str.length / size)
    const chunks = new Array(numChunks)
    for (let i = 0, x = 0; i < numChunks; ++i, x += size) {
        chunks[i] = str.substr(x, size)
    }
    return chunks
}

const getWordDec = (word) => {
    return [...word].map(c => c.charCodeAt(0).toString());
}

const getWordHex = (word) => {
    const hex = crypto.createHash('sha256').update(Buffer.from(word)).digest('hex');
    const chunked = splitByChunk(hex, 8).map(e => `0x${e}`);
    return chunked.map(e => parseInt(e, 16).toString());
}

const addressToUintArray = (address) => {
    // Remove the '0x' prefix from the address
    address = address.replace(/^0x/, '');

    // Convert the address to a BigInt
    const addressBigInt = BigInt(`0x${address}`);

    // Create an empty array for the result
    const result = new Array(8);

    // Split the BigInt into chunks of 32 bits
    for (let i = 0; i < 8; i++) {
        result[7 - i] = Number(addressBigInt >> BigInt(32 * i) & 0xFFFFFFFFn).toString();
    }

    return result;
}


module.exports = {
    getWordDec,
    getWordHex,
    addressToUintArray
}