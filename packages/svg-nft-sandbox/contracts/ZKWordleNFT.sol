// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";

import './libraries/NFTDescriptor.sol';

/// @title Describes NFT token positions
/// @notice Produces a string containing the data URI for a JSON metadata string
contract ZKWordleNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    constructor()ERC721("ZKWordleNFT", "ZKW") {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    mapping(uint256 => NFTDescriptor.ConstructTokenURIParams) public tokenURIParams;

    function setMinter(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, _minter);
    }

    function mint(address userAddress, uint256 _tokenId, string memory _word, uint256 _nonce, uint256[30] memory _colors) public onlyRole(MINTER_ROLE) {
        string memory black = "#000";
        string memory yellow = "#ffcc00";
        string memory green = "#00cc00";
        string[5][6] memory colors;
        uint256 k = 0;
        for (uint256 i = 0; i < 6; i++) {
            for (uint256 j = 0; j < 5; j++) {
                if (_colors[k] == 1) {
                    colors[i][j] = black;
                } else if (_colors[k] == 2) {
                    colors[i][j] = yellow;
                } else if (_colors[k] == 3) {
                    colors[i][j] = green;
                }
                k++;
            }
        }

        tokenURIParams[_tokenId] = NFTDescriptor.ConstructTokenURIParams({
            tokenId: _tokenId,
            word: _word,
            blockNum: block.number,
            nonce: _nonce,
            colors: colors,
            tokenAddress: address(this)
        });

        _safeMint(userAddress, _tokenId);
    }

    // ERC721のtokenURIと被るとethers.jsがバグって呼び出せなくなるるので一旦別名で定義
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        NFTDescriptor.ConstructTokenURIParams memory constructTokenURIParams = tokenURIParams[_tokenId];

        return NFTDescriptor.constructTokenURI(constructTokenURIParams);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
