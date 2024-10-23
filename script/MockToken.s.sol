// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StandardToken} from "../src/mock/MockToken.sol";

contract DeployMockToken is Script {    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        StandardToken _standard = new StandardToken("USDC", "USDC", 6, 10 ether);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_standard)
        );
    }
}
