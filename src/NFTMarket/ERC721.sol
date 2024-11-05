// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyERC721 is ERC721URIStorage {
    uint256 private _tokenIds;

    constructor() ERC721(unicode"MyNFT", "DwouraNFT") {}

    function mint(address to, string memory tokenURI) public returns (uint256) {
        _tokenIds+=1;

        uint256 newItemId = _tokenIds;
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}