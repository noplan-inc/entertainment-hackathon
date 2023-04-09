// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./AnswerVerifier.sol";


contract ZKWordle is Ownable, AnswerVerifier {
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

    function bytes32ToUintArray(bytes32 data) public pure returns (uint[8] memory) {
        uint[8] memory result;

        // Split the bytes32 into chunks of 32 bits
        for (uint i = 0; i < 8; i++) {
            uint chunk = uint256(data << (32 * i)) >> 224;
            result[i] = chunk;
        }

        return result;
    }

    function getAnswerHash() public view returns (bytes32) {
        uint256 _round = round.current();
        return questions[_round];
    }

    function answer(Proof memory proof) public {
        bytes32 hash = getAnswerHash();
        // TOOD: すでに回答された問題は回答できない

        uint[8] memory _answer = bytes32ToUintArray(hash);

        require(super.verifyAnswer(proof, _answer), "Answer is wrong");
    }
}
