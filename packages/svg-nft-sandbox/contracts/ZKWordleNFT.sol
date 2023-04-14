// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import './libraries/NFTDescriptor.sol';

/// @title Describes NFT token positions
/// @notice Produces a string containing the data URI for a JSON metadata string
contract ZKWordleNFT is ERC721 {

    constructor()ERC721("ZKWordleNFT", "ZKW") {
    }

    function mint() public {

    }

    function tokenURI(uint256 _tokenId, string memory _word, uint256 _nonce, string[30] memory _colors)
    // function tokenURI()
        external
        view
        returns (string memory)
    {
        // uint256 tokenId = 1;
        // string memory word = "HELLO";
        // uint256 blockNum = block.number;
        // uint256 nonce = 45454545;
        // string memory black = "#000";
        // string memory yellow = "#ffcc00";
        // string memory green = "#00cc00";
        // address tokenAddress = address(this); 
        // string[5][6] memory colors = [
        //     [black, yellow, black, black, yellow],
        //     [black, yellow, black, black, black],
        //     [black, black, green, black, yellow],
        //     [black, black, green, black, yellow],
        //     [green, black, black, green, black],
        //     [green, green, green, green, green]
        // ];
        string[5][6] memory colors;
        uint256 k = 0;
        for (uint256 i = 0; i < 5; i++) {
            for (uint256 j = 0; j < 6; j++) {
                colors[i][j] = _colors[k];
                k++;
            }
        }
        return
            NFTDescriptor.constructTokenURI(
                NFTDescriptor.ConstructTokenURIParams({
                    // tokenId: tokenId,
                    // word: word,
                    // blockNum: blockNum,
                    // nonce: nonce,
                    // colors: colors,
                    // tokenAddress: tokenAddress
                    tokenId: _tokenId,
                    word: _word,
                    blockNum: block.number,
                    nonce: _nonce,
                    colors: colors,
                    tokenAddress: address(this)
                })
            );
    }
}
