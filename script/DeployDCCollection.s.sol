// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Script, console } from "forge-std/Script.sol";
import { DCCollection } from "../src/samples/DCCollection.sol";

contract DeployDCCollection is Script {
    function run() external {
        string memory name = vm.envOr("COLLECTION_NAME", string("DigitalCollectibles"));
        string memory symbol = vm.envOr("COLLECTION_SYMBOL", string("DC"));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address issuer;
        try vm.envAddress("ISSUER_ADDRESS") returns (address _issuer) {
            issuer = _issuer;
        } catch {
            issuer = vm.addr(deployerPrivateKey);
        }

        vm.startBroadcast(deployerPrivateKey);
        DCCollection collection = new DCCollection(name, symbol, issuer);
        vm.stopBroadcast();

        console.log("DCCollection deployed at:", address(collection));
        console.log("  name   :", name);
        console.log("  symbol :", symbol);
        console.log("  issuer :", issuer);
    }
}
