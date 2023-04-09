// This file is MIT Licensed.
//
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

contract Verifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x205a58987bc6ccdb0d64cbe8017b93fe0b4a850612d415a428d5853d80ed4368), uint256(0x03891d562d8fdc9d7882d9c1f70a9955275102121fb13aa9a0538c6e07a828e1));
        vk.beta = Pairing.G2Point([uint256(0x2493122b26c3cee9c4c705edf9554a80000cfc0f9f6e21935cfe4fdc4beaf2ee), uint256(0x05bb5c643d43f968dd96d3c72a19343f118aa20dfec8d96e092472d1e9850bf5)], [uint256(0x1e68f78600e7d2de6fb95bec2de1a0ce6636415691e57a5b71b1710df793257e), uint256(0x15e5680115b9c9a4580844705af0c6765511ce7463f0f20c4526efc403e48f02)]);
        vk.gamma = Pairing.G2Point([uint256(0x0c4e9e7acd18c11b56376f0819ed712d03b918fcd0fd88773b4b46538da7e8fb), uint256(0x1d56507e01fd5b0a425581073dcd25cf4de3f71512260382e24d0897a6761cd7)], [uint256(0x06526ea9b07e825ddc5cd8628ca68df32f5a4489c0486242724fd738328135ce), uint256(0x04de2c450c8da82f1b4b4472efb3ec291d3afd842da6d23bc5e55fbde4694b08)]);
        vk.delta = Pairing.G2Point([uint256(0x006717abb4bea60fe2e0bbd97b852a99b3663faa64dcb63c1f3240a66d5c3789), uint256(0x14e94e7c3d4e9c4459ed4babff127920fdc12c459f9946569dbe6c42ed9ce2b4)], [uint256(0x2cddf9cf70ca4b30a945b96d47536af31a3914d1a7ade59c23a07b1edf03da8a), uint256(0x2d73cf07d9dfe639954eb36dfdb8187e57d86c28cbd3005cf071c2d4a51c7c5e)]);
        vk.gamma_abc = new Pairing.G1Point[](18);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0a2a3728df1473a82f2c3740229b3a3a1dc8357956dcdbb0f0f5d01849bc07b6), uint256(0x0be350c2616ad1e275e806b4fd45154e6b89d0c88167fe559c358a67923330e5));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x24c6f7fe951fceff94748dbb4530e0d213760a2c99142d02eeb640b95500cf4a), uint256(0x1e83e32358d87a5d62b0577be680b5e71f336644b4e938861b0ba9b155b88ef7));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x019469b9f40a363fc06e64184412ab5c14f3f04719d73c5c0931ec12215a6d8d), uint256(0x1d9b7a8b6287ecece61172f7c09ef4f7729072513abe59707ee3f23e1685324e));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x17387e71861f5b7e3ea9c13b21dfee3c15744bf12b1770c12cb129d45078c64c), uint256(0x1e414605be98d80333825a014a77615cf06ca03ac409625ad1ccf4858dbcc56e));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0cd41e799502a11688afe06cdd8a80aade5bee7e4ca9b6c297a98e7ce10458f4), uint256(0x200fc0f11a45ce6fd0ae189cfef375e1e3494a5c115910b16ddb60e56b2d3d27));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x135202cc3d4733672e1fd215faa64da2c00f55961e3b22f566d841e924a8b2ba), uint256(0x189b4fcae6bd484dad642977a7201772f3a061ce90ad8f58b69a437722eba4fc));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1933fa46b82a43a3b448eef308f1b39de2a947b97dff18853f9771650982e609), uint256(0x2599d41841cd7b29965ac6c305f18ad8dcb8742431b9d2f3aa7068e5a535b7dc));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1fae031a0e1afbf7c88777ebc835370e25d7c34f2d969f74f486134a1868f50a), uint256(0x077ac6abfab9a6049ac2628c160d614b19e18e7a734dffd9d229cfa5d19b3288));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0273100a119e64ea48a875603e43c4dd9dbb18d096e510a1b5a238cc630ff299), uint256(0x1de95e43082ec23d23b5a2981927e5f981704389d268b9af9a55035b6a32b931));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0b960185d03bdb0d7f890efd42e6f25f0dfc7d954d463a4eb9fd706269c094b6), uint256(0x12a2538a85fa9dca68f43c9183e6ee6522dadaf341d78ce252b8e50fd4af8f6e));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1880974d4025ce29e44b77138ed90960d88c1dc6cf7844324b144b1a647e849d), uint256(0x10f29b739e7c2039c42de10c40bb507a64c206f75f56f925634a7d8097e983d5));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x2928c56628e9e403f179c80cef8267eedefb60b1492c0bbf20ecffdd69d16985), uint256(0x0c85bdd4bfbae4a3c0cc0df057413125ae1c5cea66ab4972403293c459184363));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x2d17d545ef475096f4e53c7a62b61da0b303bdf3ee0409a43d65ee793d9d5ecf), uint256(0x0247b6fd75e43938379ebd82424c8c08604fa05bde27b2b0bc53703fb5faa4cc));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x2aa4c10d41e7746e621fc0bdf70a380b72748690f7ac159f5718ed4aa605bda7), uint256(0x2d4fac72c167849e959c37b0613ba537dc0c3260ae21215b4892622c4fcaa3b0));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x21ffd2d433e0526fb0fd1538c84e567155aa3f4794a86201f479d4e528d1f455), uint256(0x11d169920d7de6285f9b441744e7e8b71fde6f9d5af1b31626a3100b96a394f3));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x05bdf9e0f50c6d555dc1544bf9e9ab1df8f4b50341ef762e61a5dc92d84c4831), uint256(0x0df0f0e4eaf27f791c258bfc78d6f77249827d1e111f660f8894c8ef9b5e644c));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x013510b6fb32d287d366be44357020ca9ac892baa29dc4e32e34a3a0890d24e4), uint256(0x2102b4ad76a4d1b1835f45d71058f6fdb9df954d8929a6c239cbaf685676dab0));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x045f71670c0a7af55e6e8f856646f828579076dd856a0d590818da5325228694), uint256(0x0273e6743090b3b8983caf302928b7f0fe74a4dba484835650a7ac10d64e9563));
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
    function verifyTx(
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
