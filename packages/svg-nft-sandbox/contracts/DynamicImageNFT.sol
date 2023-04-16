// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


library DynamicImageSVG {
    using Strings for uint256;

    struct SVGParams {
        uint256 width;
        uint256 height;
        string backgroundColor;
        string textColor;
        uint256 fontSize;
        string text;
        uint256 blockNumber;
        uint256 nonce;
    }

    function generateTextTag(string memory value, uint256 yPos, string memory fontSize, string memory textColor) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<text x="50%" y="', yPos.toString(),
            '%" dominant-baseline="middle" text-anchor="middle" font-size="',
            fontSize, '" fill="', textColor, '">', value, '</text>\n'
        ));
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory) {
        string memory fontSize = params.fontSize.toString();

        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
            params.width.toString(), ' ', params.height.toString(), '">\n',
            '<rect x="0" y="0" width="100%" height="100%" fill="', params.backgroundColor, '"/>\n',
            generateTextTag(params.text, 50, fontSize, params.textColor),
            generateTextTag(string(abi.encodePacked("blockNumber: ", params.blockNumber.toString())), 70, fontSize, params.textColor),
            generateTextTag(string(abi.encodePacked("nonce: ",params.nonce.toString())), 90, fontSize, params.textColor),
            '</svg>'
        );

        return string(svg);
    }
}

contract DynamicImageNFT is ERC721 {
    using DynamicImageSVG for DynamicImageSVG.SVGParams;
    mapping(uint256 => string) private _tokenURIs;
    
    

    constructor() ERC721("DynamicImageNFT", "DINFT") {}

    function mint(
        uint256 tokenId,
        uint256 width,
        uint256 height,
        string memory backgroundColor,
        string memory text,
        string memory textColor,
        uint256 fontSize,
        uint256 nonce
    ) public {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, generateImage(width, height, backgroundColor, text, textColor, fontSize, block.number, nonce));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), _tokenURIs[tokenId]));
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    

    function generateImage(
        uint256 width,
        uint256 height,
        string memory backgroundColor,
        string memory text,
        string memory textColor,
        uint256 fontSize,
        uint256 blockNumber,
        uint256 nonce
    ) public pure returns (string memory) {
        DynamicImageSVG.SVGParams memory params = DynamicImageSVG.SVGParams(
            width,
            height,
            backgroundColor,
            textColor,
            fontSize,
            text,
            blockNumber,
            nonce
        );

        return params.generateSVG();
    }
}
