// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ChildUSDb} from "../../src/core/child/ChildUSDb.sol";

contract DeployChildUSDbTestnet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        
        vm.startBroadcast(deployerPrivateKey);
        ChildUSDb _childUsdb = new ChildUSDb(endpoint, admin);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_childUsdb)
        );
    }
}
