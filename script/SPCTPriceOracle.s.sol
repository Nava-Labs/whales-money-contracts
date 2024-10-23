// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { SPCTPriceOracle } from "../src/core/oracle/SPCTPriceOracle.sol";

contract DeploySPCTPriceOracleTestnet is Script {
    function launch() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    
        vm.startBroadcast(deployerPrivateKey);
        SPCTPriceOracle _oracle = new SPCTPriceOracle();
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_oracle)
        );
    }
}
