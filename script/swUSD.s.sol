// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {swUSD} from "../src/core/swUSD.sol";
import {RewardDistributor} from "../src/core/RewardDistributor.sol";
import {wUSDFlat} from "../src/core/wUSDFlat.sol";
import {swUSDOFTAdapter} from "../src/core/swUSDLayerZeroAdapter/swUSDOFTAdapter.sol";
import {WhalesMoneyLayerZeroAdapter} from "../src/core/swUSDLayerZeroAdapter/WhalesMoneyLayerZeroAdapter.sol";

contract DeployswUSDTestnet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        IERC20 asset = IERC20(0x14eCa3b25aCCaaeebe291275d755123633206BA5);
        uint24 cdPeriod = 600;
        
        vm.startBroadcast(deployerPrivateKey);
        swUSD _swusd = new swUSD(admin, asset, cdPeriod);
        _swusd.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _swusd.grantRole(keccak256("YIELD_MANAGER_ROLE"), admin);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_swusd)
        );
    }
}

contract DeployswUSDOftAdapterTestnet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address token = 0x109b9Ffb62622A500B6641b10FE98e71eed4671F;
        address lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        address owner = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        
        vm.startBroadcast(deployerPrivateKey);
        swUSDOFTAdapter _oftAdapter = new swUSDOFTAdapter(token, lzEndpoint, owner);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_oftAdapter)
        );
    }
}
