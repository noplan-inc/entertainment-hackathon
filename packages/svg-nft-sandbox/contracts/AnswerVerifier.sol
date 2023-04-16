// SPDX-License-Identifier: MIT

// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


import "hardhat/console.sol";

pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract AnswerVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x1c3268d3be53ac2148103b10b341368ff2c988c46a7f6e03d2d0c7790e6a2267), uint256(0x07cf5c3cf65af3fd7932603bf64e4bab5b933012fe54bc544ab25a1c61fbe638));
        vk.beta = Pairing.G2Point([uint256(0x06acc6ade14a5e44e34b6ef01bb66fc14be2648f474b672cc69b7a66c2a15116), uint256(0x210387fc9e9950998181e55022db0b2511629c49c530c7843af112c4bb84a5f7)], [uint256(0x0de277d5dba97cf3fa56a0d46c1f3e74ae523998bc21e0d89c4856d9de5ae468), uint256(0x04ab937614cb27c2ded5a3d77f7e1c8e786606a4392ac666d2d8a87dc707fc67)]);
        vk.gamma = Pairing.G2Point([uint256(0x06d5aff7bd6e3f77cb12f3e5a45f5e80f697141b2581b2a6814f6c3956dab34b), uint256(0x2a1ae1d4ad03a73e99009e64be62b61d2489f8fd9add023bcd4a982de3ffd6dd)], [uint256(0x1767b51b530adee0ac49e8012009b96befc13d42b5aaa6633093c653081a3c25), uint256(0x19fa9c99feec8f9afbfa578dfea2feec03fced8160fd58ac0eeb3b4c94049110)]);
        vk.delta = Pairing.G2Point([uint256(0x00ee0a088ebdc6234e6c6b413aace3ed14c86f989886e417cb2893421d72765c), uint256(0x2316831d9069bc9b973cd24dd08fc36122e6a727eb776ba21da8ce29f725f88a)], [uint256(0x2ea60ae3c87d3f1f6b7122ebfc2901c23dce8b16253bff76d530e0ff4cf266e3), uint256(0x1a3c4041e2bb63935e735a8df712b385b53b2138295fedc612e413c6af339e5c)]);
        vk.gamma_abc = new Pairing.G1Point[](18);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2d2f1dfd9d5502f257430fe24aed2ff6e2db4541d0920ae6c3f67fbbd30295be), uint256(0x24da76a67652cc3b64fb00eec7fe5c8253389ba4bb403887d02ef75d7d4f9aa8));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1fbe27859817cbb7d45f7f0a62e5318aefb3173db514133b16c4278cc72470a6), uint256(0x22fdb361451c2714872ae686633c19e4223e55bcd5c48e66909ac533d9c047d0));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x25ba826aa5e6ba29151fdff9da39eb94b0dcc3431efc585aebd527255a69d5bd), uint256(0x149f16fc93f69ef5b67139e9db17785baa00bccbc06ddfbf5eb467ba68405c7a));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2f59210fba7613c76d855090e7c4a338d88549ef6b3658a95dae5bdc86fd458e), uint256(0x26e5ed426cf769c5be35f62d897a34aefb68aa5bc8ee53e202461ff2efb91e58));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0cd4621bee0802da5a8e5f9c2b04c1b70f9dd5ea44c15fa7489a0bd739a3a254), uint256(0x172a3e69e847da3108525988d47e8f4a4ba03986821c694f5b895d44507f22ff));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x21c68d24cd800e2c9858a0c3807ec3ef91a79bc6b0faf209007c077362e5429c), uint256(0x095572ab6bc3e660b9040036b183b9d67db8d34e0e84d87f230b22989182212e));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0a829d8ee426b89f8f37276fed97e9f7679f43421c33d0c02b6150e77ef14713), uint256(0x0ada7491cdf38b6ea2a92e7d7b43b2da120f23e0ef532f0c2b295cb601e16032));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x13bc7f3b042687b5ccc4cb941896b46b84957fe2dd144dcc1f137e3537de0ddd), uint256(0x16e3df2bbc57d6df0c48f69770518bd0f7c61b78e2509aa0d90e9ea49329975f));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2c08b50fe76a8e3a1d77b13655fd0630a11232f03d8eb32dc78905dddde6b189), uint256(0x13dc78145f627ab75108b0c7677dadcc5d64a9bf78854fd1db32a75b5be2bf5c));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x20d2d87f496cf19f7c94e2ae16cc9e16d461edf1ab58a25ca9510585c971f33e), uint256(0x11f01aedb5d2d57e7d941ed100892f31951d7b2bfa68d7ce46d91a6d8c20f84e));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2058fc4089bad736cc84610ae867307792919db70eb430c919ae36c9c12c0627), uint256(0x0b4bf696986dd823b006b46c77a459f1b9bfe82b3b9fafe678baae91aee0d286));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x1aa41e4de5ff9aa7c2955355c195dcc66fbe7af368525dbeb508daa44c8467f8), uint256(0x15b5acbcf98cb870bfba120c3e594beb518420c00e3d2c861f151ab9ea0c670b));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x126eb139390dcedac549a441afa8e115619f8323240ed5995e99b166bb5c1343), uint256(0x2aa9a838c9de5bccad6d06ed2bd451433f64736a1e57901b8d4871d7aa64993b));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x2ce82af66240338d681484a80076b1d7a8b908a79cada3dda9a6ec66a6a767d8), uint256(0x11f49cdd40818b2f4735fadd936a466bdcc6df36c21c7a9e0bf728ef4239d78d));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1f555a48441a5a78493a2ce3979b16ad11cdbfc2f85dbd6b6268bee48ccc2b7e), uint256(0x0728d944775a8c3fd95cff9f7f8e8dfb1a562401ec6499e32a43c7e70c427412));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x15bfab1cc186cb5ba46442955c6dee385715b4ff1982815a9cdde10c723d1c34), uint256(0x076a899e00f77f3f52cb48362921d38b928a6cc9c1543717714cbd394602a492));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x25b6ed53f6fdb2648f1a226ad7ea98c21f0c9adf6a5fe256c0f698fd6be8273a), uint256(0x0779f9ca7959a432a3933f8fe4c101e5db2714e2d5013a008311c9dcea86f8f2));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x14fbe3e03492c1de44cdab73d277d09b57b94c62ff43b4ff363f1a3a97ee4e97), uint256(0x1bbcdba7c8ec1d178026a539e7dc7e1644cf19f7c4f9c06902473e4155d4a77f));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function addressToUintArray(address addr) public pure returns (uint32[8] memory) {
        uint32[8] memory result;

        // Convert address to uint
        uint addrUint = uint(uint160(addr));

        // Split the uint into chunks of 32 bits
        for (uint i = 0; i < 8; i++) {
            result[7 - i] = uint32(addrUint & 0xFFFFFFFF);
            addrUint >>= 32;
        }

        return result;
    }
    function verifyAnswer(
            Proof memory proof, uint[8] memory expectedHash, address sender
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](17);
        
        // 
        for(uint i = 0; i < 8; i++){
            inputValues[i] = expectedHash[i];
        }

        // フロントランニング対策
        uint32[8] memory _addresses = addressToUintArray(sender);
        for(uint i = 0; i < 8; i++){
            inputValues[i + 8] = _addresses[i];
        }

        // outputがtrueになることを検証
        inputValues[16] = 1;

        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }

    function verifyTx(
            Proof memory proof, uint[17] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](17);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
