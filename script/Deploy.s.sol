// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {InstantRNG} from "../src/InstantRNG.sol";
import {console} from "forge-std/console.sol";

contract DeployInstantRNG is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deterministic deployment using CREATE2
        // We use a salt to ensure the same address across different chains
        bytes32 salt = keccak256(abi.encodePacked("InstantRNG_v1"));

        InstantRNG rng = new InstantRNG{salt: salt}();

        console.log("InstantRNG deployed to:", address(rng));

        vm.stopBroadcast();
    }
}
