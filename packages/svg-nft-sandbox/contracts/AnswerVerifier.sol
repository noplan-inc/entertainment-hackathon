// SPDX-License-Identifier: MIT

// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
        vk.alpha = Pairing.G1Point(uint256(0x047addd5f93a39c53e67286240593cb61b620eb4779827a92a71ddeab02780c2), uint256(0x1ddd458ec84ffe58c37bdebeb142e1cd9963ad1ad0f2bc9dd199be408af6b725));
        vk.beta = Pairing.G2Point([uint256(0x16c3a33d289e48f9b09f30fe64c89fbaa8793ea657c1406472df558978cf4d3d), uint256(0x2b4105f3153093a98c892b5c623478444d52d3a7cb7752f6c0dc5aaf21c533cb)], [uint256(0x2c246ec9dafedf9103fe048fb6cea1d02f9fc8fa43196ab1642f1e47e1ccda6f), uint256(0x04cf37ec6037eef3bd2c55f2b7dbd83e83a9827e8dc18300d20701a3eb05e89b)]);
        vk.gamma = Pairing.G2Point([uint256(0x2bf53ef27f2b5297c34c4e9ff1c5eb982fc900262bf698d70902c2c3c1cd02f5), uint256(0x2fe45e1a233d1ed29d00449d93993e54ecab95d898e20707908ba7b0c0a07f33)], [uint256(0x06510f34eb4c208bf8a7843da0679d2184e4240e0c7f5ad0520be6a6076f891c), uint256(0x2182cc530a5d3443fcb7e9122e066fb100387ddf28a88b4ce0132136a3a9d895)]);
        vk.delta = Pairing.G2Point([uint256(0x18c25de65565b0a2c17a4e6652870058cc877f3a4b809adb5a1bfebf2cfec08a), uint256(0x16e73bc923c4746b91f06210a4ae716d5e247783a88767c6e34bb0055138c0d0)], [uint256(0x0c4d968867e1ecb816dcde6ccb4c26ebf4fc9f0e0dcb44bd85933571f258be91), uint256(0x0d6e9482861e17e479de499d9ac89c138382b63e3f029a7f865c51eb46f554c9)]);
        vk.gamma_abc = new Pairing.G1Point[](18);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0a5ceb70303b4c87203e3398be1cefdade8dfbf8c32b1534f91c318251b82b06), uint256(0x0c0eb383d68ff7f9820b8820dcc730a23675aa68efcc94329634658a863e8072));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x178e7c60b5ac2cc6bee9ae896e255ad36be0285e21e27676c17c4d903fb55f37), uint256(0x251d7e41af94686522d74a589974dfea62ee89ec4b501a7de05709bc35c6be9b));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x076bde55b0b76d280df68927ca73463f22090c7a6c1dc0dcab0ffeb7331d5e41), uint256(0x1af84e1028e5d0c89cb2f319aba76196ba1c3f5df7eabf49d38fa0a1edff77cf));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x09dd331366f4c9f8deea15a0eb7733b3059dae7ed6404f88af817872764e8f2e), uint256(0x13729fee782446930e389390f4b3e2162caf3323045099416349ea7ea5751eff));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x174c9570ff20911cc9a51115eb9cc62328613c9e5b3fbb316a490e5b7fe66c91), uint256(0x074376ee56ca3181b78c2307882928eaeb02ea1fded2eb354149e87af0552364));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0136ba045c1c1f2ccfa2bb8118d4bc97a38473f7eb63f9537856a4593e4c6cb3), uint256(0x2ced2822fecb9532178e8c251ee8c24ab4566f6102c247d340ba3b97e66ef763));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0e6da47d760be1b8937d5d5c52ad300c7720e14b67ace6b0263643b42dee65e3), uint256(0x0180cec6faf6ee88b0bfe13dbef13abb871758bac099f58a8ad7364b6d6859dc));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1413c68ba3f857d0cd13d31d277eb8a68f6e7e71ebb9146a5e5c26540ace363e), uint256(0x0fca96cc0c9715975ecc7e084a94463981adf4da4c02f6b9d9f4b3b395cc5339));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2bfaa99928999d3a470457b07c988a490ac92de23ace4f4f1343b0a9b00f5c3f), uint256(0x22ced69f8d12d1ca9aea390279d77e1d5b386bee57539f82cebdda37e9bc88b7));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x019870927209bff2a5f0e138a7d61a1f279166df9725b05190a67ec0bf7d763f), uint256(0x1d8f177ade5cba7032cc4d6a3724c35b681aae5661202aa477cf5d11f572b5f8));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1332b1f5ed8bfdc97b3eb829188036ef52f7a277432c1571050036789cf9b94b), uint256(0x039b253032b16520fd2d074eb4694aed685c042879aae9b91b7b839daa5638b7));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x2d5343d7dc6e2ff93d28e3cb80ce57df9af788f484ded20870caa297c44e9411), uint256(0x1eab57dccbc90675f458fc652f74dec101e6193c367c99b81731205562125fac));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x0224a85e4a262849ad319b688304a7c9bf80e59a49c7720c8c24a88c10570756), uint256(0x19d54bf6cc799328830a25f0c60bf590bef98d4967e3320b60685eaad02313be));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x13a9266bc89b04134b58046fca254ea4e2d99ea450255a74c7abcacf34a6a898), uint256(0x07a62fa2dcffe1b916fe95f053278e998ecb36c8260c48f571794b08e06d4082));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x0cdccacbc2f06c8198b2881a60af82f99d9486969dddc8864acf676d3dc3368e), uint256(0x1d643d1c717553f978de14c43e230bd0a181d0319d2b54bc1e2c702d8f1961c9));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x1341a340e105677f7ca3eda18e57ad42b097d0ba5fd8450fa71cbe09abbd6b8b), uint256(0x084ab4573169a3f71264e1117f7e78695063b4163923adc8fb7e08f71b9c9cc3));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x2feb651adbd34981ed1f33f000178d7f79020d742422d909f1c524ec1f43eddb), uint256(0x0a53d820ff747fac20446f38529892f196db36b852ba67b78d86a1b862eb1643));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x032865cd582e1b8a7c9ba58668b3ec91f6e7aca836f821f8d441be7511e91897), uint256(0x189eb8488f3b7ac2402b1b67d039d9ace0897b18f2126610c5620e8280d53255));
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
            Proof memory proof, uint[8] memory expectedHash
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](17);
        
        // 
        for(uint i = 0; i < 8; i++){
            inputValues[i] = expectedHash[i];
        }

        // フロントランニング対策
        uint32[8] memory _addresses = addressToUintArray(msg.sender);
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
}
