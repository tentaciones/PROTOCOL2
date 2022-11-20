// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NitroFinaceLiquidityPositions is ERC721, ERC721Burnable, Ownable {
    constructor() ERC721("NitroFinaceLiquidityPositions", "NLP") {}

    function safeMint(address to, uint256 tokenId) public  {
        _safeMint(to, tokenId);
    }
}