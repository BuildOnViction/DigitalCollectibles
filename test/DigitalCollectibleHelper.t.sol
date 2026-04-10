// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/samples/DCCollection.sol";
import "../src/helpers/DigitalCollectibleHelper.sol";

/// @title DigitalCollectibleHelper Solidity Unit Tests
contract DigitalCollectibleHelperTest is Test {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------
    string constant NAME = "New Collection";
    string constant SYMBOL = "New";

    // Far-future deadline (matches TS: 10000000000000)
    uint256 constant DEADLINE = 10_000_000_000_000;

    // Private keys for signers
    uint256 constant OWNER_KEY = 1;
    uint256 constant RECEIVER_KEY = 2;
    uint256 constant SPENDER_KEY = 3;

    // -------------------------------------------------------------------------
    // State — re-deployed in setUp before every test
    // -------------------------------------------------------------------------
    DCCollection collection;
    DigitalCollectibleHelper helper;

    address owner;
    address receiver;
    address spender;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------
    function setUp() public {
        owner = vm.addr(OWNER_KEY);
        receiver = vm.addr(RECEIVER_KEY);
        spender = vm.addr(SPENDER_KEY);

        // Deploy NFT — owner is the issuer so onlyOwner mint works
        vm.prank(owner);
        collection = new DCCollection(NAME, SYMBOL, owner);

        // Deploy helper (constructor: name, symbol, decimals — matches TS "Helper","HELPER",0)
        helper = new DigitalCollectibleHelper("Helper", "HELPER", 0);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    /// @dev EIP-712 permit signature (single token)
    function _signPermit(uint256 signerKey, address spenderAddr, uint256 tokenId, uint256 nonce, uint256 deadline) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(collection.PERMIT_TYPEHASH(), spenderAddr, tokenId, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", collection.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        return abi.encodePacked(r, s, v);
    }

    /// @dev EIP-712 permitForAll signature
    function _signPermitForAll(uint256 signerKey, address spenderAddr, uint256 nonce, uint256 deadline) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(collection.PERMIT_FOR_ALL_TYPEHASH(), spenderAddr, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", collection.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // =========================================================================
    // Tests
    // =========================================================================

    /// @notice "Should mint NFT"
    function test_MintNFT() public {
        vm.prank(owner);
        collection.mint(owner, 1);

        assertEq(collection.ownerOf(1), owner);
    }

    /// @notice "Permit through Helper"
    /// Helper calls permit() on the NFT contract on behalf of the caller.
    function test_PermitThroughHelper() public {
        // Mint token 1 first
        vm.prank(owner);
        collection.mint(owner, 1);

        uint256 nonce = collection.nonces(1); // 0
        bytes memory sig = _signPermit(OWNER_KEY, spender, 1, nonce, DEADLINE);

        helper.permit(address(collection), spender, 1, DEADLINE, sig);

        assertEq(collection.getApproved(1), spender);
    }

    /// @notice "Permit for all through Helper"
    /// Helper calls permitForAll() on the NFT contract; nonce increments.
    function test_PermitForAllThroughHelper() public {
        // Mint token 1 first (matches TS which minted it in "Should mint NFT")
        vm.prank(owner);
        collection.mint(owner, 1);

        uint256 nonce = collection.nonceByAddress(owner); // 0
        bytes memory sig = _signPermitForAll(OWNER_KEY, spender, nonce, DEADLINE);

        helper.permitForAll(address(collection), owner, spender, DEADLINE, sig);

        assertTrue(collection.isApprovedForAll(owner, spender));
        assertEq(collection.nonceByAddress(owner), 1);
    }

    /// @notice "Transfer through Helper"
    /// Owner grants helper as operator via permitForAll, then helper transfers the token.
    function test_TransferThroughHelper() public {
        // Mint token 1
        vm.prank(owner);
        collection.mint(owner, 1);

        // In the TS test nonce is 1 (after "Permit for all" ran first in the same shared context).
        // Here each test is independent so nonce is 0.
        uint256 nonce = collection.nonceByAddress(owner); // 0
        bytes memory sig = _signPermitForAll(OWNER_KEY, address(helper), nonce, DEADLINE);

        helper.permitForAll(address(collection), owner, address(helper), DEADLINE, sig);

        // helper.transferNFT calls transferFrom(msg.sender, to, tokenId).
        // msg.sender here is this test contract (address(this)).
        // But owner is the token owner — we need the call to originate from owner so that
        // transferFrom(owner, receiver, 1) resolves correctly.
        // The helper is an operator for owner, so transferFrom(owner, receiver, 1) must be
        // called by the helper itself.  We call helper.transferNFT as owner; inside the
        // helper transferFrom(msg.sender=owner, receiver, 1) is invoked.
        vm.prank(owner);
        helper.transferNFT(address(collection), receiver, 1);

        assertEq(collection.ownerOf(1), receiver);
    }

    /// @notice "Multi call"
    /// Batch a permitForAll + transferNFT into a single multicall from owner.
    function test_Multicall() public {
        // Mint tokens 1 and 2
        vm.startPrank(owner);
        collection.mint(owner, 1);
        collection.mint(owner, 2);
        vm.stopPrank();

        // In the TS test token 2 is minted inside the "Multi call" it-block and nonce is 2
        // (accumulated from prior shared-state tests).  Here each test is independent so
        // nonce for owner is 0.
        uint256 nonce = collection.nonceByAddress(owner); // 0
        bytes memory sig = _signPermitForAll(OWNER_KEY, address(helper), nonce, DEADLINE);

        bytes memory permitData = abi.encodeCall(helper.permitForAll, (address(collection), owner, address(helper), DEADLINE, sig));
        bytes memory transferData = abi.encodeCall(helper.transferNFT, (address(collection), receiver, 2));

        bytes[] memory calls = new bytes[](2);
        calls[0] = permitData;
        calls[1] = transferData;

        // multicall uses delegatecall so msg.sender is preserved.
        // permitForAll is called with msg.sender=owner (no auth restriction there).
        // transferNFT calls transferFrom(msg.sender=owner, receiver, 2) — owner is the
        // token holder and helper is operator after permitForAll.
        vm.prank(owner);
        helper.multicall(calls);

        assertEq(collection.ownerOf(2), receiver);
    }
}
