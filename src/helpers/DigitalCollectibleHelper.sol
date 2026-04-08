// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { DigitalCollectible } from "../DigitalCollectible.sol";
import { ZeroGasOwnable } from "../libraries/ZeroGasOwnable.sol";

contract DigitalCollectibleHelper is ZeroGasOwnable {
    constructor(string memory name, string memory symbol, uint8 decimals) { }

    function permit(address collection, address spender, uint256 tokenId, uint256 deadline, bytes memory signature) external {
        DigitalCollectible(collection).permit(spender, tokenId, deadline, signature);
    }

    function permitForAll(address collection, address owner, address spender, uint256 deadline, bytes memory signature) external {
        DigitalCollectible(collection).permitForAll(owner, spender, deadline, signature);
    }

    function transferNFT(address collection, address to, uint256 tokenId) external {
        DigitalCollectible(collection).transferFrom(msg.sender, to, tokenId);
    }

    function multicall(bytes[] calldata data) public returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}
