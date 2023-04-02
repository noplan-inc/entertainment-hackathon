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
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
            params.width.toString(),
            ' ',
            params.height.toString(),
            '">\n<rect x="0" y="0" width="100%" height="100%" fill="',
            params.backgroundColor,
            '"/>\n<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="',
            params.fontSize.toString(),
            '" fill="',
            params.textColor,
            '">',
            params.text,
            '</text>\n</svg>'
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
        uint256 fontSize
    ) public {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, generateImage(width, height, backgroundColor, text, textColor, fontSize));
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
        uint256 fontSize
    ) public pure returns (string memory) {
        DynamicImageSVG.SVGParams memory params = DynamicImageSVG.SVGParams(
            width,
            height,
            backgroundColor,
            textColor,
            fontSize,
            text
        );

        return params.generateSVG();
    }
}
