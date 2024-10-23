// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SUSDb} from "../src/v1/sUSDb.sol";
import {RewardDistributor} from "../src/v1/RewardDistributor.sol";
import {USDbFlat} from "../src/v1/USDbFlat.sol";

contract DeploysUSDBTestnet is Script {
    function launch() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        IERC20 asset = IERC20(0xB815Dc78787BC09F8D4aC5dbA6C401c27E088727);
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
