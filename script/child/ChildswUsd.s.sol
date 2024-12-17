// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ChildswUSD} from "../../src/core/child/ChildswUSD.sol";
import {WhalesMoneyLayerZeroAdapter} from "../../src/core/swUSDLayerZeroAdapter/WhalesMoneyLayerZeroAdapter.sol";
import {IBridgeToken} from "../../src/core/swUSDLayerZeroAdapter/OFTExternal.sol";

contract DeployChildswUSDTestnet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address l1Token = 0x109b9Ffb62622A500B6641b10FE98e71eed4671F;
        address l2Bridge = 0x531ef787DE4D22e5b12Db6585Ef877992C973b06;
        
        vm.startBroadcast(deployerPrivateKey);
        ChildswUSD _childswUDB = new ChildswUSD(l1Token, l2Bridge);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_childswUDB)
        );
    }
}

contract DeployWhalesMoneyLayerZeroAdapter is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        IBridgeToken bridgeToken = IBridgeToken(0xc2594A133589e40Baeb34D8985F24499E54d9C17);
        address lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        address owner = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        
        vm.startBroadcast(deployerPrivateKey);
        WhalesMoneyLayerZeroAdapter _oftAdapter = new WhalesMoneyLayerZeroAdapter(bridgeToken, lzEndpoint, owner);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_oftAdapter)
        );
    }
}
