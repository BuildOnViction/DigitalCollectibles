// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Script, console } from "forge-std/Script.sol";

contract ApplyZeroGas is Script {
    address issuer = 0x8c0faeb5C6bEd2129b8674F262Fd45c4e9468bee;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address collection = address(vm.envAddress("COLLECTION_ADDRESS"));

        vm.startBroadcast(deployerPrivateKey);
        (bool success,) = issuer.call{ value: 10 ether }(abi.encodeWithSignature("apply(address)", collection));
        require(success, "Failed to apply");
        vm.stopBroadcast();

        console.log("Sucessfully apply ZeroGas:");
        console.log("  collection:", collection);
    }
}
