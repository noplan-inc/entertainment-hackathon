// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


contract Nonce is Ownable {

    mapping (uint256 => uint256) public nonces;
    constructor() {}

    function setNonce(uint256 _round) public onlyOwner {
        nonces[_round] = block.prevrandao;
    }

    function getNonce(uint256 _round) public view returns (uint256) {
        return nonces[_round];
    }
}