// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ChildsUSDb} from "../../src/core/child/ChildsUSDb.sol";
import {BondlinkLayerZeroAdapter} from "../../src/core/sUSDbLayerZeroAdapter/BondlinkLayerZeroAdapter.sol";
import {IBridgeToken} from "../../src/core/sUSDbLayerZeroAdapter/OFTExternal.sol";

contract DeployChildsUSDbTestnet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address l1Token = 0x109b9Ffb62622A500B6641b10FE98e71eed4671F;
        address l2Bridge = 0x531ef787DE4D22e5b12Db6585Ef877992C973b06;
        
        vm.startBroadcast(deployerPrivateKey);
        ChildsUSDb _childsUDBb = new ChildsUSDb(l1Token, l2Bridge);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_childsUDBb)
        );
    }
}

contract DeployBondlinkLayerZeroAdapter is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        IBridgeToken bridgeToken = IBridgeToken(0xc2594A133589e40Baeb34D8985F24499E54d9C17);
        address lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        address owner = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        
        vm.startBroadcast(deployerPrivateKey);
        BondlinkLayerZeroAdapter _oftAdapter = new BondlinkLayerZeroAdapter(bridgeToken, lzEndpoint, owner);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_oftAdapter)
        );
    }
}
