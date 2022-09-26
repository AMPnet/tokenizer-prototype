// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NftBasicMintable is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private baseURI;

    constructor(string memory tokenName, string memory symbol, string memory baseURI_) ERC721(tokenName, symbol) {
        baseURI = baseURI_;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    function mint(address owner, uint256 count) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            uint256 id = _tokenIds.current();
            _safeMint(owner, id);
            _tokenIds.increment();
        }
    }
}
