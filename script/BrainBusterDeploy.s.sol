// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {BrainBusterProfile} from "../src/BrainBusterProfile.sol";

contract BrainBusterDeploy is Script {
    uint256 public constant ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    function run(address admin) external returns (BrainBusterProfile) {
        deployerKey = ANVIL_PRIVATE_KEY;

        vm.startBroadcast();
        BrainBusterProfile profileContract = new BrainBusterProfile(admin);
        vm.stopBroadcast();

        return profileContract;
    }
}
