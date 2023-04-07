// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract ZKWordle is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public round;

    mapping(uint256 => bytes32) public questions;
    
    constructor() {}

    function createQuestion(bytes32 _answerHash) public onlyOwner {
        uint256 _round = round.current();
        questions[_round] = _answerHash;
        round.increment();
    }

    // RANDAOの値を返すview関数
    function getRandao() public view returns (uint256) {
        return block.prevrandao; // block.difficulty
    }
}
