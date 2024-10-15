// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { SPCTPool } from "../src/v1/SPCTPool.sol";

contract DeploySPCTPoolTestnet is Script {
    function launch() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        IERC20 usdc = IERC20(0x0fbbE1770F92eD1ef5B951d575cE81B6F80bBeb2);
        
        vm.startBroadcast(deployerPrivateKey);
        SPCTPool _spctPool = new SPCTPool(admin, usdc);

        _spctPool.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_spctPool)
        );
    }
}