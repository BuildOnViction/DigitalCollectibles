// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { IERC4494 } from "./IERC4494.sol";

interface IDigitalCollectible is IERC721, IERC4494, IERC721Metadata {
    /// @notice Function to approve by way of owner signature, for all Collectibles os owner
    /// @param owner the address initiated the approval
    /// @param spender the address to approve
    /// @param deadline a timestamp expiry for the permit
    /// @param signature a traditional or EIP-2098 signature
    function permitForAll(address owner, address spender, uint256 deadline, bytes memory signature) external;

    /// @notice Returns the nonce of an address - useful for creating permits
    /// @param owner owner address to get the nonce of
    /// @return the uint256 representation of the nonce
    function nonceByAddress(address owner) external view returns (uint256);
}
