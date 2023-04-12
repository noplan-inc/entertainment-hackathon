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
        vk.alpha = Pairing.G1Point(uint256(0x11aadd332a3cf7b9ac2a6bb319a269e4b9479634fc319bd81180ca0844c1cfe9), uint256(0x2b3011b96bd78f87e0d10cfba27b8782cc6781d0a5084f344528eb047f43c0b5));
        vk.beta = Pairing.G2Point([uint256(0x23a80e99ea24aa1885baa8da147f8e7ce958c92b32244d0cb2ee255304777179), uint256(0x176695c5523ef0aa60558f39f99573a7df4e2674ade95236ecc379f39e150a6b)], [uint256(0x084937a6954b525d892ba3741c00db8d1a59a7f6b61317ebf59e3e3928fc4d2e), uint256(0x1354e66e2a6db0d64ec358d6b90de043650bd3b9963311bd1d4adb8325a436e1)]);
        vk.gamma = Pairing.G2Point([uint256(0x08addf3a0c90c0a2cfa5069ab81adfbb20ca297852f0e38498b46bf70112930f), uint256(0x0e022b60be0c537e90af0c3af8fcffc696d0ad178596d414c7b4e57cbfb97e28)], [uint256(0x286dbd91bbd5817214e6f3a8de090a570a0062e2a5ba9d61f677ceee8d9346e7), uint256(0x0bf5baec647f5a044c401a9dc3a11c7c957221ccd176aee2b94632eeb980f883)]);
        vk.delta = Pairing.G2Point([uint256(0x05f1944e7f1a1c0d882a1d09415b811c7bd491d65f0ffe22af91234b412bec94), uint256(0x218ddf150546fc57f96a4a02101ce8623dc34a25fc09b91d81179b3c7269b5bf)], [uint256(0x15afd720e0025c9b1f2a1609d0079535cc7cab52c5881274209f885770ff39a9), uint256(0x1c5f1d4322cbe3c36f2ff8d71bb39b7ec8cf7dd2537c91779c2ee4837a2e9709)]);
        vk.gamma_abc = new Pairing.G1Point[](18);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1ddbe22c46ffd3c2d041330a028618de7514aaba64bb98aea52572a1791ded53), uint256(0x1a3eb110fb36aba1ba3c280658dd60478e6e14e15f64478614f93f0413e7dcb2));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x00e04f2e63ce21d560fc365cd9291b03a223cd80a99a8ffc4ad9e5712ec71c0a), uint256(0x080926a4108ed10a8322ab3e8384c77d2cbd9eba7d1208a9d9c67bc386b36aeb));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0cd6d917373ba0965f6a7bbcb8d297834f88851ebd1b9b25d1b3dfdaf4c0981b), uint256(0x3021a087dc650c69f2359a352b3f43b554c6ae2e23618caaa910d8e66c43752f));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x286ac1fed77daa5c44bb5be18d954994eed8094fe73a89964c1bd223aa61f400), uint256(0x262c90810ad77cefb9b4e4c64aaf7e0573987cb79e1902171b91ebb58e260563));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x209fc23db57737933f3c562df01f3095e7a21aecc7400210c606ed51a07bd12a), uint256(0x0db7c58f1dad6c0b6eb0fc3c3e1e2199894ca4235c9f899608fdf6f1d1b9c8e7));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1b52e04aa6912b97e248522b3864361c3dbd33e456421bc8d84e5ae42933a81a), uint256(0x1bbadc2d7f588856473e7f607c44f1acaf7a3a151c2870a9855a10fcafe1fc0f));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2932cccb743206d3037fc41bc051d7831547d5f838dc0ae6bacc92804bbe76a4), uint256(0x1d38e02f25492468a1995068f50c8db77a251689e25358184b9177b04b631408));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1ce32df5fadede6093b19aca444540faf1d866756b410f255ba18db5d9c37754), uint256(0x1841e8ca3bf38c92fec27e72fcef5fee577e19a73ba1529c782f6e91de1f88ad));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x20663b18ba283c10f589949673c0e9942f51a554bd3c79cb02c938079714a549), uint256(0x0f936688e899ea9fd0d351dcfe17ee80e2009e69e2d8ed673bc86b994468d210));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x032eaecb7f83201e27417a143bd18b41c1b9217e1f08fe3a58b9f9765199c934), uint256(0x26223c9f3f708b0de4122b7a48735ccc2e20c420809ff2646958e38dd5f1e580));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x28e8ee0566e48c4d16d0ad83cd7a58786c60f92790e7f8858a09a945c3da1987), uint256(0x2c3fe7e8f94ba2811425f25b2029406574097b1ef022e34f63b7eb1b7ce74c42));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0b2f3c779c6848a49fb66866362c7e284c8324b39d25d1023a4f40cccaafbde9), uint256(0x04d2dcd94401fa88d6adaf5aec6c9d72f9f350b5e8a13a5822ce5296981500bc));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x1a614407101339388663fe3759f8708a35e4b59f411fa7713423ada7a227efc9), uint256(0x080c38830f6690ffc945a6f5b0ae00e723c8e85460aded8bbcab018781ad2899));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1dd8a34a964c335ce915c3a58dae0df18e7fb549d62ae49401dcd985754c9f14), uint256(0x1823b7937d2b4a67787b4614a17134f7121cc978cd24f67de7baa147547356fd));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1d50eb117bbe421bff9d294a2fa91870bf7dd424ba135481de698549c6ce1ee6), uint256(0x17184369ec8a1aac208c9a9edac5a1c7f0e1770814fca38f71113be8a578636a));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x11700595fdbe78e9594a93fc520b24d41f0215d58ea885a93166364282fe36d9), uint256(0x0031a747e5ed587c41ec89c9a3460ccce8541e4324b29d46154f915fbfdcab7d));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0072b8b4cfcabfeabf43858688c6ac974f4280efc87feee6a1672e244aca7e44), uint256(0x08e6a22ed8099b9c000ad40ebd9698a46b5328fe39f1c15f5d4e03f362501644));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x28a20d5642c4b01a4424142ef4e321620a3db2dcd2f2080140fb302dded8014f), uint256(0x23cc191535653373ed81ed71bfcb2712d4c797d27494efd68088e79cefe34935));
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
