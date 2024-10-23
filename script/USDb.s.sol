// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {USDb} from "../src/core/USDb.sol";
import {ISPCTPool} from "../src/interfaces/ISPCTPool.sol";
import {ISPCTPriceOracle} from "../src/interfaces/ISPCTPriceOracle.sol";

contract DeployUSDBTestnet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        address endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        uint24 cdPeriod = 300;
        IERC20 usdc = IERC20(0xB1d7B2e0597Bac1f4335ecB437Bf8277e478B978);
        ISPCTPool spct = ISPCTPool(0xa524f70eA27e24EB3011C4A7C361a53dD42f4890);
        ISPCTPriceOracle oracle = ISPCTPriceOracle(0xCa593b4429E4Ed86D26C8202593Ab85d617E73C1);
        
        vm.startBroadcast(deployerPrivateKey);
        USDb _usdb = new USDb(admin, endpoint, usdc, spct, oracle, cdPeriod);
        _usdb.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_usdb)
        );
    }
}

contract Interaction is Script {
    function deposit(address _usdb, address receiver, uint256 _amount) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        USDb(payable(_usdb)).deposit(receiver,_amount);
        vm.stopBroadcast();
    }

    function depositSPCT(address _usdb, uint256 _amount) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        USDb(payable(_usdb)).depositBySPCT(_amount);
        vm.stopBroadcast();
    }

    function redeem(address _usdb, uint256 _amount) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        USDb(payable(_usdb)).cdRedeem(_amount);
        vm.stopBroadcast();
    }

    function redeemSCPT(address _usdb, uint256 _amount) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        USDb(payable(_usdb)).cdRedeem(_amount);
        vm.stopBroadcast();
    }
    
}
