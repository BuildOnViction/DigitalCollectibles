// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../DigitalCollectibleEnumerable.sol";

contract TestCollection is DigitalCollectibleEnumerable {
    constructor(string memory name, string memory symbol, address issuer) {
        __DC_init(name, symbol, issuer);
    }

    function mint(address owner, uint256 tokenId) external onlyOwner {
        _safeMint(owner, tokenId);
    }
}
