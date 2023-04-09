// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import './libraries/ChainId.sol';
import './interfaces/INonfungiblePositionManager.sol';
import './interfaces/INonfungibleTokenPositionDescriptor.sol';
import './interfaces/IERC20Metadata.sol';
import './libraries/PoolAddress.sol';
import './libraries/NFTDescriptor.sol';
import './libraries/TokenRatioSortOrder.sol';

/// @title Describes NFT token positions
/// @notice Produces a string containing the data URI for a JSON metadata string
contract NonfungibleTokenPositionDescriptor is ERC721 {

    constructor() {
    }

    function mint(){

    }

    /// @inheritdoc INonfungibleTokenPositionDescriptor
    function tokenURI(INonfungiblePositionManager positionManager, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        tokenId = 1;
        word = "Hello";
        blockNum = 12121212;
        nonce = 45454545;
        return
            NFTDescriptor.constructTokenURI(
                NFTDescriptor.ConstructTokenURIParams({
                    tokenId: tokenId,
                    word: word,
                    blockNum: blockNum,
                    nonce: nonce
                })
            );
    }
}
