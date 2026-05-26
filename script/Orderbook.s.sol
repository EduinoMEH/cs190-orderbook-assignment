// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {Orderbook} from "../src/Orderbook.sol";

/// @title Orderbook bundled deploy script (Sepolia)
/// @notice Deploys Mock1, Mock2, then Orderbook(Mock1, Mock2) in one go.
///         Logs all three addresses at the end — copy the Orderbook address
///         into your submission.
///
/// Usage:
///   forge script script/Orderbook.s.sol \
///     --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
contract OrderbookScript is Script {
    function run() public {
        vm.startBroadcast();

        MockERC20 mock1 = new MockERC20("Mock1", "M1");
        MockERC20 mock2 = new MockERC20("Mock2", "M2");
        Orderbook orderbook = new Orderbook(address(mock1), address(mock2));

        vm.stopBroadcast();

        console.log("=== Deployment complete ===");
        console.log("Mock1 (base) :", address(mock1));
        console.log("Mock2 (quote):", address(mock2));
        console.log("Orderbook    :", address(orderbook));
        console.log("Submit the Orderbook address for grading.");
    }
}
