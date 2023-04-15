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
        vk.alpha = Pairing.G1Point(uint256(0x16bbd2a5178cd7ad89367e461a7a488153ff8f22eb333c02d0244ea27c8acf0f), uint256(0x06b5b8e90965f31c01467ded487b514fbd84c65350c45682f3daa96b8fcec74a));
        vk.beta = Pairing.G2Point([uint256(0x0f9c7f6d68d8976ea433672d8181a16878e86055652bcdfa58af4ef094a5efa5), uint256(0x2fb75b0f83c2234d7847487579e6fed64b678b39165fc56c11f517e4e2bf3c49)], [uint256(0x144d625dbbe4d857e12c0284223887cc94cc901ef2cb6b47b4cb5b0cb01f40d1), uint256(0x1ef02e3947d9511edcb65cbb11c27556f6a7b999d2d63211f87cb7a7b0897763)]);
        vk.gamma = Pairing.G2Point([uint256(0x1f6b59e42c39b2cb7219277ae246c211a9cf2e830e704ea5f4dc459944b3d2c6), uint256(0x2c26a1ab56f9e311bf5c6e8fe4cdaa66228de7627a8bf2d5a5fcbf76980070f5)], [uint256(0x1de39a0845254385dab4a29fa2f1f6a1c807381faf29ecb838e8d2000cd53c2f), uint256(0x287b8fb72608aca2f5293c8f5467f26d3dc91446036d3e2a1f0e5fb5676bef5d)]);
        vk.delta = Pairing.G2Point([uint256(0x0c29817e615c2cda0035a1150e43812ed820d84dcbb82449b8f3ca00b6ddcb0a), uint256(0x146d9aff6406211b4accf3d4b40dfa991643b6384caa55240228f4fa6e5e012d)], [uint256(0x0948db4540eca63205247781a57c1ae5729786db60fc0bf776c6e666fe16cdd1), uint256(0x2bf59d49b10ece7ebd2027fcc3975d3cf3df4fee8f44783394b3738ee6abf9b8)]);
        vk.gamma_abc = new Pairing.G1Point[](18);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1bee3f8016e3c18ecd4dcc1f52aa75b31f77f3b8e588fb7140ca6a7ff9c39f96), uint256(0x12f1256e3ee708a817f806db14f5b29a75235cb0ecffa45968ddbd4d706bbe28));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0fa76c88632ca82a81892f68e4accf043065cfce6c4e87137d5239f3a2fbba50), uint256(0x227e32fb21c52af57d772129dd6b02796947fb805073203f1db797a339765462));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x12650bdf8eb2b373dae8975e302e51785307ebf4c844f504b1fc8d362da13808), uint256(0x249dc8d11119de7145cff41196d6e67a143801f77a68987f5b95304cf1e9b4a2));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1ba55762086b9f0fcbbe7caa936386a80824a51cddb98b167a397a478d605ee9), uint256(0x0e8ff144ec2e7c7a7b1a3a31efeb8782a33308f1d157574424750c8940fc48f7));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1ed1e735538d8d61222fc7343dffac86730fede950708f2d6437a892f4457182), uint256(0x07931a55f9e350badb4cdd56a186dc8ea11639a0cfd3a51a490b8f6c5be02c61));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x2e6321bc553c8b53e3abb491bfcdc00aa2b86bcf05c3a0f547316ab8d9afac81), uint256(0x17683ba736699f74f983d3ce4ee1faada8b68d77ec964e7e52a896cda367b41a));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x03c04e26f5ee4f0916ad0d2459ebd8b542469786f7fdd7d91f6586564221629e), uint256(0x0e7f532a04db3fd7e0509a921b594b89e05a5f46750a584a3dc13293d719c85d));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x0a9b3661a53b1c88556bbed97f30a46368b24d04c4d7b558c92a8220e056d80a), uint256(0x101ecd568447feabbba4172552b2aa07ca2cc64519244da50b43e523bb874ef3));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x257b8a2f8e32d5920c68ae249959b09004bd1c7b6661790d23a0e0b5e9a6511d), uint256(0x0caa05c0e4e5d899ffec812fa494ecfabcec6c899dd68185ec3449e85e55840b));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0c9dfa29fe20e6bfff18af2faa1b9296a60cd09a93c53f58b51b3ffc991c20ef), uint256(0x14ddbd4ea518410733ca8c689bcddcf8a06d29c16c240879a10469b11013105f));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1b3637be6307bd6af80e415b3101639636ebfa33d3c6cfef056c4b9e80f4d0ab), uint256(0x1bb09276fa8525cfb678a13d54999f4b653c100babd02c027915ee5c42e5ed58));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x1593dbf2a6a68b6bca77ad09259663e0a564ddcf63de1601941a088076badeff), uint256(0x0988dc9dbb46e09fdff7ea3305d1206622cb937f0b9cd487749d2253cc9363c5));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x18243fdfa275f2596ec52f49adf62085e5e5b2d59116bf29ec32d1e4537beb8d), uint256(0x003ea8bcb4b1bb205143c6fa838ca5a583db7b72409710f18f44863d932efe18));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x0d638a69022f7afb5116e31b689d33b494a742209c926fac03fdced31a96a9a9), uint256(0x11a41ce741350910e716d608d18073972a43b87849795d99f1f6913f71514e57));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1e31f1f5be449cb5b5ab747e1c04e18e319c40160bdf10ca9e0aec3697fb6fe5), uint256(0x2ffdd1b0fe1fbb3746ef226847bc86f66a0d565b6351cd538bd1624e7f0f08b3));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x0f4b7b2b05a97b058863589bce620e828ff0d789df52ee293c201496a4a3278c), uint256(0x0a05f39040729e857cfb2deaabf9ea0c311f9e161708fcd9ff3f6bd104419ac3));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x06ee0d5735aad04b68f2077684699620d61ff7c12ea77904c33b66c732e18e9b), uint256(0x21f99d7e13efce05567f476290bf73a3b96a0ea25c6636c7f5cc5f88772315ca));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x1da8a714c289ce6174fff4c7fdbc74b81ff00a8d5cc1ebc4b0cb26793c7ba4c1), uint256(0x1a2a1b0c9e57fc4e8ee264a761d7c063831043a7e2599533ea99c889605c8baa));
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
