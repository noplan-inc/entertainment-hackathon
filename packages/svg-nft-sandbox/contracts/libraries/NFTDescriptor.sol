// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import './NFTSVG.sol';

library NFTDescriptor {
    using Strings for uint256;
    using Base64 for bytes;

    bytes16 internal constant ALPHABET = '0123456789abcdef';

    struct ConstructTokenURIParams {
        address tokenAddress;
        uint256 tokenId;
        string word;
        uint256 blockNum;
        uint256 nonce;
        string[5][6] colors;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) public pure returns (string memory) {
        string memory name = generateName(params);
        string memory descriptionPartOne = generateDescriptionPartOne(params.word);
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                descriptionPartOne,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateDescriptionPartOne(
        string memory _word
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'This NFT represents you clear the game and get the "',
                    _word,
                    '" in a ZKWordle'
                )
            );
    }

    function generateName(ConstructTokenURIParams memory params)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'ZKWordle - ',
                    params.word
                )
            );
    }
    

    function addressToString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }

    function generateSVGImage(ConstructTokenURIParams memory params) internal pure returns (string memory svg) {
        NFTSVG.SVGParams memory svgParams =
            NFTSVG.SVGParams({
                tokenAddress: addressToString(params.tokenAddress),
                word: params.word,
                tokenId: params.tokenId,
                blockNum: params.blockNum,
                nonce: params.nonce,
                colors: params.colors
            });

        return NFTSVG.generateSVG(svgParams);
    }
}
