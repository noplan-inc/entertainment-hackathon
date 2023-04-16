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
        vk.alpha = Pairing.G1Point(uint256(0x0fa8bf6e225f2cfe682ebe1276d912298c62c8e4f209a894e70b76ec3baa2f5d), uint256(0x0b308748f7e5ae9525d03a7b9403c0f6592b4174637d76e16ea8b6412ad11d90));
        vk.beta = Pairing.G2Point([uint256(0x26d2652d8d5f248ef1e3c918e419bac8abd7e43c242696520fcb42c5cad17637), uint256(0x109c4cc38ce294959a32ff7357c2990f10c1512bc6ed3602ab6b1b6210c24dd0)], [uint256(0x0a935e2133d234f2713840edf14cec4a5cba0926f1b6033dcb1818c5b5993bfb), uint256(0x03899f069b32578ac97d8a7b589c53ca5c50c731d2f552b8b3f4e063d90905ae)]);
        vk.gamma = Pairing.G2Point([uint256(0x0aa7fc5d229ead3a50afcf4397a92a70295451183506d6b469a2893cce1fd2be), uint256(0x06451a5b96d9e38f1a5ac61530addac250fb399ab251cd957154ef7a40f6153b)], [uint256(0x0f64b9b08f800ec3f1f94d6eb3aec2b4e0e22e14f7f4f4c4a66792072c765abe), uint256(0x201ae98f997260c694c3aec26b71b665e5c38b2673b17a2e27aec6b0bcb83555)]);
        vk.delta = Pairing.G2Point([uint256(0x04b5a615c1a314fab14c5b4fa6e0d34ee573d3452c327e4747c6afef797e09c6), uint256(0x0d2e19d4efae70acb5ddf590e7c3d51642cadaf7e4447b63df4deabc949e1265)], [uint256(0x036b22fc046992782d65d5872ff6b825646161dc9e12ed042f65870c56698a65), uint256(0x114cc1e704f1d969c03aa526ef3b0625bf0c336e0f8e8de52bac8ffc967f6b77)]);
        vk.gamma_abc = new Pairing.G1Point[](18);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x23eddeb3b78cf51f8f7367bd8686a9c35b503c3cfccd054711f7fa3c066237e5), uint256(0x11f90c620c904fd48312496a5d28b1028e1d2a1f9d4eff39c563607fddd28fec));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x07a759a7b12f5d55c719c23bdd6437902308d5d63858e5be527dc1dd63f8f8b1), uint256(0x2e284b41a385db5483616d051761e2474e39d70c016c26df8c026f9bf719155b));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x27e06380e06e39401882ef09378bc9d94d3f6f794b6f26c5b72df47b8a1e368e), uint256(0x0973ed633acc95834423b3cd2cab0e3a9d5d50161eaa5b546371ace5e4f99992));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2a067774379fd7b54712ca224734c8b2736c9d5ea502b4ea08250b3b145e82ce), uint256(0x2e5a9aed3a32ef895fb105ef8d3fa8c070456693a58bde6dab0a0159572b30ba));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x18e92bfb495eee40c0a4098da6bfa640452a1d04fe2bfdaec69e349871880c26), uint256(0x1008452784b66fa58afd8db9a7ca9d53fb1194db1c0843bfcadf616369e4abb7));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x184d9f3cfbb81f15657fa9f8662f3cd5eacc5878149fa798373b3bf95a48a485), uint256(0x1b137aa912970a6a94369eae864e55dbc16d2ebe656d06720d29d7722f1c7a1e));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2b23096357ef8023fa6483f09f57d461b58651d37f618daed5583e091ce10f7c), uint256(0x29bd41523bad35ada2703a5ee096be8c8dfc93120679dc57ae932b1c46ab5309));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x14ed29269c873aa4e465984f2465d26c26c62520ee885b12b95dbfdb894ec10d), uint256(0x02101ccc3d525358e3edeb611e8a606b652087e22e553f1d31a6917eccfbcfb7));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x010d26a9f3e8876acde671b47fc7b064d5c98d1e4598e8e5dd9466b76229ead9), uint256(0x093f776898693d7a082813870e9e6518957702a77edb6cf68c490a0df94c5a69));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x161ad04f5097816a806a36743d3893ae6c32a7d7da0afc3a325ea78c8181012c), uint256(0x20101b4c5508e6b3d45aacd97010da21da6208edc376d7cbc6afcbe377515e05));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x26d50b14a4093ec571a028210eed46b83ab4cec3266f8f6825405c9dbbf74676), uint256(0x138cf49762c3e4e34ce3c082c0ecc3bcb797ef0386d2d36460ef3275d919e486));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x07c97bdbb8cc8c58b6fe972d9ae128a09c48f1976676cc7ba8184d6317460263), uint256(0x185219e0d66a7431dac66192913ee4e9e44aec1a222229444a743ed7f8847e21));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x0624b97b64a50d6b0a67fe97154b3fb589a51268752592e309999fcb0e96f38b), uint256(0x0d277e2fcf63f4fbcd54f1eafbffe68fed3c4d36a76a4ef6899e72d932bd093d));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1ead2be66df5ee9ef48dade0415986d3c669f442b736850db308cdf18ba371c9), uint256(0x2c1adf13a31be012ea475b80aac5770934b5737a96c2b6bacf48376f16a2f96c));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x19fe2117edfd59fa673b79d9c4e0f1880f741cd23eea27fc5f602a5b3e8c049c), uint256(0x124afd87c0858a1304234c7fe050266e3760d4476401dafc41cb6f86344e782d));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2d7fc44dc8fa125cb3445d57bb7a9df68ed08422f6e524b5f56be031c065302b), uint256(0x0b018513e071edae11fbd7377d920a1be4ab0a1a9169d77f325580643a4f9009));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0fa9cbb297c4541a5d77749090e0947459cac45549338cd1edadf3caa7c288c8), uint256(0x0f0e62c5f9e982e331505d0446220ad8d463037a776c219276bbe9d8ad60b818));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x0494d7f62f64357ab31653ba71f44f6693b9096a31fa090163df10dfe10c7842), uint256(0x0692c849ff8a23620155714e9697a5c171283afc6b3045b8ec632d936b2fff18));
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
