// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/tests/TestCollection.sol";

/// @title DigitalCollectible Solidity Unit Tests
contract DigitalCollectibleTest is Test {
    // -------------------------------------------------------------------------
    // Constants mirroring the TypeScript test file
    // -------------------------------------------------------------------------
    uint256 constant firstTokenId = 5042;
    uint256 constant secondTokenId = 79217;
    uint256 constant nonExistentTokenId = 13;
    uint256 constant fourthTokenId = 4;
    string constant TOKEN_NAME = "Test NFT";
    string constant TOKEN_SYMBOL = "Symbol";

    // Far-future deadline (matches TS: 10000000000000)
    uint256 constant DEADLINE = 10_000_000_000_000;

    // Private keys for signers (vm.addr(key) gives the corresponding address)
    uint256 constant OWNER_KEY = 1;
    uint256 constant NEW_OWNER_KEY = 2;
    uint256 constant APPROVED_KEY = 3;
    uint256 constant ANOTHER_APPROVED_KEY = 4;
    uint256 constant OPERATOR_KEY = 5;
    uint256 constant OTHER_KEY = 6;

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------
    TestCollection token;

    address owner;
    address newOwner;
    address approved;
    address anotherApproved;
    address operator;
    address other;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------
    function setUp() public {
        owner = vm.addr(OWNER_KEY);
        newOwner = vm.addr(NEW_OWNER_KEY);
        approved = vm.addr(APPROVED_KEY);
        anotherApproved = vm.addr(ANOTHER_APPROVED_KEY);
        operator = vm.addr(OPERATOR_KEY);
        other = vm.addr(OTHER_KEY);

        // Deploy as owner so onlyOwner mint works
        vm.prank(owner);
        token = new TestCollection(TOKEN_NAME, TOKEN_SYMBOL, owner);

        // Mint firstTokenId and secondTokenId to owner (matches TS beforeEach)
        vm.startPrank(owner);
        token.mint(owner, firstTokenId);
        token.mint(owner, secondTokenId);
        vm.stopPrank();
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    /// @dev Build an EIP-712 permit signature for a single token
    function _signPermit(uint256 signerKey, address spender, uint256 tokenId, uint256 nonce, uint256 deadline) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(token.PERMIT_TYPEHASH(), spender, tokenId, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        return abi.encodePacked(r, s, v);
    }

    /// @dev Build an EIP-712 permitForAll signature
    function _signPermitForAll(uint256 signerKey, address spender, uint256 nonce, uint256 deadline) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(token.PERMIT_FOR_ALL_TYPEHASH(), spender, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // =========================================================================
    // balanceOf
    // =========================================================================

    function test_BalanceOf_OwnsTokens() public view {
        // "returns the amount of tokens owned by the given address"
        assertEq(token.balanceOf(owner), 2);
    }

    function test_BalanceOf_NoTokens() public view {
        // "returns 0"
        assertEq(token.balanceOf(other), 0);
    }

    function test_BalanceOf_ZeroAddress_Reverts() public {
        // "throws"
        vm.expectRevert("DC: address zero is not a valid owner");
        token.balanceOf(address(0));
    }

    // =========================================================================
    // ownerOf
    // =========================================================================

    function test_OwnerOf_TrackedToken() public view {
        // "returns the owner of the given token ID"
        assertEq(token.ownerOf(firstTokenId), owner);
    }

    function test_OwnerOf_NonExistent_Reverts() public {
        // "reverts"
        vm.expectRevert("DC: invalid token ID");
        token.ownerOf(nonExistentTokenId);
    }

    // =========================================================================
    // transfers
    // =========================================================================

    /// @dev Shared assertion helper mirroring TS transferWasSuccessful()
    function _assertTransferSuccessful(address fromAddress, address toAddress, uint256 tokenId) internal view {
        // transfers the ownership of the given token ID to the given address
        assertEq(token.ownerOf(tokenId), toAddress);
        // clears the approval for the token ID
        assertEq(token.getApproved(tokenId), address(0));
        // adjusts owners balances
        assertEq(token.balanceOf(fromAddress), 1);
        // adjusts owners tokens by index (always present — TestCollection is Enumerable)
        assertEq(token.tokenOfOwnerByIndex(toAddress, 0), tokenId);
        assertNotEq(token.tokenOfOwnerByIndex(fromAddress, 0), tokenId);
    }

    function test_Transfer_ByOwner() public {
        // "when called by the owner — should transfer successful"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.prank(owner);
        token.transferFrom(owner, newOwner, firstTokenId);

        _assertTransferSuccessful(owner, newOwner, firstTokenId);
    }

    function test_Transfer_ByApproved() public {
        // "when called by the approved individual — should transfer successful"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.prank(approved);
        token.transferFrom(owner, newOwner, firstTokenId);

        _assertTransferSuccessful(owner, newOwner, firstTokenId);
    }

    function test_Transfer_ByOperator() public {
        // "when called by the operator — should transfer successful"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.prank(operator);
        token.transferFrom(owner, newOwner, firstTokenId);

        _assertTransferSuccessful(owner, newOwner, firstTokenId);
    }

    function test_Transfer_ByOperatorWithoutApproved() public {
        // "when called by the owner without an approved user — should transfer successful"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        // Clear the per-token approval
        vm.prank(owner);
        token.approve(address(0), firstTokenId);

        vm.prank(operator);
        token.transferFrom(owner, newOwner, firstTokenId);

        _assertTransferSuccessful(owner, newOwner, firstTokenId);
    }

    function test_Transfer_ToSelf() public {
        // "when sent to the owner — should transfer successful"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.prank(owner);
        token.transferFrom(owner, owner, firstTokenId);

        // transfers ownership
        assertEq(token.ownerOf(firstTokenId), owner);
        // clears approval
        assertEq(token.getApproved(firstTokenId), address(0));
        // balance stays at 2 (self-transfer)
        assertEq(token.balanceOf(owner), 2);
        // still in owner's enumeration at index 0
        assertEq(token.tokenOfOwnerByIndex(owner, 0), firstTokenId);
    }

    function test_Transfer_IncorrectOwner_Reverts() public {
        // "when the address of the previous owner is incorrect — reverts"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.expectRevert("DC: transfer from incorrect owner");
        vm.prank(owner);
        token.transferFrom(other, other, firstTokenId);
    }

    function test_Transfer_NotAuthorized_Reverts() public {
        // "when the sender is not authorized for the token id — reverts"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.expectRevert("DC: caller is not token owner or approved");
        vm.prank(other);
        token.transferFrom(owner, other, firstTokenId);
    }

    function test_Transfer_NonExistentToken_Reverts() public {
        // "when the given token ID does not exist — reverts"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.expectRevert("DC: invalid token ID");
        vm.prank(owner);
        token.transferFrom(owner, other, nonExistentTokenId);
    }

    function test_Transfer_ToZeroAddress_Reverts() public {
        // "when the address to transfer the token to is the zero address — reverts"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.expectRevert("DC: transfer to the zero address");
        vm.prank(owner);
        token.transferFrom(owner, address(0), firstTokenId);
    }

    // =========================================================================
    // approve
    // =========================================================================

    function test_Approve_Clear() public {
        // "when clearing approval — should clear approval"
        vm.prank(owner);
        token.approve(address(0), firstTokenId);
        assertEq(token.getApproved(firstTokenId), address(0));
    }

    function test_Approve_NonZero() public {
        // "when approving a non-zero address — should approve"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        assertEq(token.getApproved(firstTokenId), approved);
    }

    function test_Approve_NotOwner_Reverts() public {
        // "when the sender does not own the given token ID — Reverts"
        vm.expectRevert("DC: approve caller is not token owner or approved for all");
        vm.prank(other);
        token.approve(approved, firstTokenId);
    }

    function test_Approve_ApprovedCantApprove_Reverts() public {
        // "when the sender is approved for the given token ID — Reverts"
        vm.prank(owner);
        token.approve(approved, firstTokenId);

        vm.expectRevert("DC: approve caller is not token owner or approved for all");
        vm.prank(approved);
        token.approve(approved, firstTokenId);
    }

    function test_Approve_ByOperator() public {
        // "when the sender is an operator — should approve"
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.prank(operator);
        token.approve(approved, firstTokenId);

        assertEq(token.getApproved(firstTokenId), approved);
    }

    function test_Approve_NonExistentToken_Reverts() public {
        // "when the given token ID does not exist — should approve (reverts)"
        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        vm.expectRevert("DC: invalid token ID");
        vm.prank(operator);
        token.approve(approved, nonExistentTokenId);
    }

    // =========================================================================
    // setApprovalForAll
    // =========================================================================

    function test_SetApprovalForAll_Approve() public {
        // "Should approval"
        vm.prank(owner);
        token.setApprovalForAll(operator, true);
        assertTrue(token.isApprovedForAll(owner, operator));
    }

    function test_SetApprovalForAll_Unset() public {
        // "can unset operator"
        vm.prank(owner);
        token.setApprovalForAll(operator, true);
        assertTrue(token.isApprovedForAll(owner, operator));

        vm.prank(owner);
        token.setApprovalForAll(operator, false);
        assertFalse(token.isApprovedForAll(owner, operator));
    }

    function test_SetApprovalForAll_Self_Reverts() public {
        // "when the operator is owner — reverts"
        vm.expectRevert("DC: approve to caller");
        vm.prank(owner);
        token.setApprovalForAll(owner, true);
    }

    // =========================================================================
    // getApproved
    // =========================================================================

    function test_GetApproved_NotMinted_Reverts() public {
        // "when token is not minted — reverts"
        vm.expectRevert("DC: invalid token ID");
        token.getApproved(nonExistentTokenId);
    }

    function test_GetApproved_NoApproval() public view {
        // "when token has been minted — should return zero address"
        assertEq(token.getApproved(firstTokenId), address(0));
    }

    function test_GetApproved_WithApproval() public {
        // "when account has been approved — returns approved account"
        vm.prank(owner);
        token.approve(approved, firstTokenId);
        assertEq(token.getApproved(firstTokenId), approved);
    }

    // =========================================================================
    // permitForAll
    // =========================================================================

    function test_PermitForAll_ValidSig() public {
        // "when signer is owner — should approve and count nonce"
        uint256 nonce = token.nonceByAddress(owner); // 0
        bytes memory sig = _signPermitForAll(OWNER_KEY, approved, nonce, DEADLINE);

        token.permitForAll(owner, approved, DEADLINE, sig);

        assertTrue(token.isApprovedForAll(owner, approved));
        assertEq(token.nonceByAddress(owner), 1);
    }

    function test_PermitForAll_InvalidSig_Reverts() public {
        // "when signer is not owner — reverts"
        uint256 nonce = token.nonceByAddress(owner); // 0
        // Sign with OTHER key, but claim it's owner's approval
        bytes memory sig = _signPermitForAll(OTHER_KEY, approved, nonce, DEADLINE);

        vm.expectRevert("DC: Invalid permit signature");
        token.permitForAll(owner, approved, DEADLINE, sig);
    }

    // =========================================================================
    // permit
    // =========================================================================

    function test_Permit_ValidSig() public {
        // "when signer is owner of token — should approve and count nonce"
        uint256 nonce = token.nonces(firstTokenId); // 0
        bytes memory sig = _signPermit(OWNER_KEY, approved, firstTokenId, nonce, DEADLINE);

        token.permit(approved, firstTokenId, DEADLINE, sig);

        assertEq(token.getApproved(firstTokenId), approved);
    }

    function test_Permit_InvalidSig_Reverts() public {
        // "when signer is not owner of token — reverts"
        uint256 nonce = token.nonces(firstTokenId); // 0
        // Sign with OTHER key, but try to approve on owner's token
        bytes memory sig = _signPermit(OTHER_KEY, approved, firstTokenId, nonce, DEADLINE);

        vm.expectRevert("DC: Invalid permit signature");
        token.permit(approved, firstTokenId, DEADLINE, sig);
    }

    // =========================================================================
    // ERC721Metadata
    // =========================================================================

    function test_Metadata_Name() public view {
        assertEq(token.name(), TOKEN_NAME);
    }

    function test_Metadata_Symbol() public view {
        assertEq(token.symbol(), TOKEN_SYMBOL);
    }

    function test_Metadata_TokenURI_Default() public view {
        // "Return default" — no baseURI set, should return ""
        assertEq(token.tokenURI(firstTokenId), "");
    }
}
