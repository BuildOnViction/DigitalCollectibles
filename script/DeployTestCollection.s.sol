// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Script, console } from "forge-std/Script.sol";
import { TestCollection } from "../src/tests/TestCollection.sol";

contract DeployTestCollection is Script {
    function run() external {
        string memory name = vm.envOr("COLLECTION_NAME", string("Test Collection"));
        string memory symbol = vm.envOr("COLLECTION_SYMBOL", string("TEST"));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address issuer;
        try vm.envAddress("ISSUER_ADDRESS") returns (address _issuer) {
            issuer = _issuer;
        } catch {
            issuer = vm.addr(deployerPrivateKey);
        }

        vm.startBroadcast(deployerPrivateKey);
        TestCollection collection = new TestCollection(name, symbol, issuer);
        vm.stopBroadcast();

        console.log("TestCollection deployed at:", address(collection));
        console.log("  name   :", name);
        console.log("  symbol :", symbol);
        console.log("  issuer :", issuer);
    }
}
