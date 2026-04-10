// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/**
 * @title ZeroGasOwnable
 * @author Viction authors
 * @notice Minimum definition to support ZeroGas for non-token smart contract with integrated Ownable2Step
 */
abstract contract ZeroGasOwnable {
    // The order of _balances, _minFee, _issuer must not be changed to pass validation of gas sponsor application
    /**
     * @dev Mapping owner address to token count
     */
    mapping(address => uint256) internal _balances;

    /**
     * @dev minFee must always be 0 to ensure that ZeroGas will work properly in the case you apply for it
     */
    uint256 internal _minFee;

    /**
     * @dev Shared field _owner and _newOwner for both ZeroGas & Ownable2Step
     */
    address internal _owner;
    address internal _newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice The amount fee that will be lost when transferring.
     */
    function minFee() public view returns (uint256) {
        return _minFee;
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ZGO: caller is not the owner");
        _;
    }

    /**
     * @notice Owner of the token
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Owner of the token
     */
    function issuer() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Accept the ownership transfer. This is to make sure that the contract is
     * transferred to a working address
     *
     * Can only be called by the newly transfered owner.
     */
    function acceptOwnership() external {
        require(msg.sender == _newOwner, "ZGO: only new owner can accept ownership");
        address oldOwner = _owner;
        _owner = _newOwner;
        _newOwner = address(0);
        emit OwnershipTransferred(oldOwner, _owner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "ZGO: new owner is the zero address");
        _newOwner = newOwner;
    }
}
