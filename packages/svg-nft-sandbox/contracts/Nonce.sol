// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Nonce {
    constructor() {}

    function getNonce() public view returns (uint256) {
        return block.prevrandao;
    }
}