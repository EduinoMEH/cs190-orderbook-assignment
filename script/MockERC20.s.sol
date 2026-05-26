// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockERC20} from "../src/MockERC20.sol";

/// @title MockERC20 standalone deploy script
/// @notice Deploys a single MockERC20. Reads `TOKEN_NAME` and `TOKEN_SYMBOL`
///         from env, defaulting to "Mock1" / "M1".
///
/// Usage:
///   TOKEN_NAME=Mock1 TOKEN_SYMBOL=M1 \
///   forge script script/MockERC20.s.sol \
///     --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
contract MockERC20Script is Script {
    function run() public {
        string memory tokenName = vm.envOr("TOKEN_NAME", string("Mock1"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("M1"));

        vm.startBroadcast();
        MockERC20 token = new MockERC20(tokenName, tokenSymbol);
        vm.stopBroadcast();

        console.log("MockERC20 deployed:");
        console.log("  name   :", tokenName);
        console.log("  symbol :", tokenSymbol);
        console.log("  address:", address(token));
    }
}
