// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SUSDb} from "../src/core/sUSDb.sol";
import {RewardDistributor} from "../src/core/RewardDistributor.sol";
import {USDbFlat} from "../src/core/USDbFlat.sol";
import {sUSDbOFTAdapter} from "../src/core/sUSDbLayerZeroAdapter/sUSDbOFTAdapter.sol";
import {BondlinkLayerZeroAdapter} from "../src/core/sUSDbLayerZeroAdapter/BondlinkLayerZeroAdapter.sol";
import {IBridgeToken} from "../src/core/sUSDbLayerZeroAdapter/OFTExternal.sol";

contract DeploysUSDBTestnet is Script {
    function launch() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        IERC20 asset = IERC20(0x14eCa3b25aCCaaeebe291275d755123633206BA5);
        uint24 cdPeriod = 600;
        
        vm.startBroadcast(deployerPrivateKey);
        SUSDb _susdb = new SUSDb(admin, asset, cdPeriod);
        _susdb.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _susdb.grantRole(keccak256("YIELD_MANAGER_ROLE"), admin);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_susdb)
        );
    }

    function launchRewardDistributor(address usdbAddress, address susdbAddress) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        RewardDistributor _rewardDistributor = new RewardDistributor(usdbAddress, susdbAddress);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_rewardDistributor)
        );
    }
}

contract DeploysUSDBOftAdapterTestnet is Script {
    function launch() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address token = 0x109b9Ffb62622A500B6641b10FE98e71eed4671F;
        address lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        address owner = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        
        vm.startBroadcast(deployerPrivateKey);
        sUSDbOFTAdapter _oftAdapter = new sUSDbOFTAdapter(token, lzEndpoint, owner);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_oftAdapter)
        );
    }
}

contract DeployBondlinkLayerZeroAdapter is Script {
    function launch() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        IBridgeToken bridgeToken = IBridgeToken(0x47C4e739ac455Eb4A2Ff129b08c6504FfeB2b554);
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
