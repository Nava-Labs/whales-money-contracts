// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {wUSD} from "../src/core/wUSD.sol";
import {ISPCTPool} from "../src/interfaces/ISPCTPool.sol";
import {ISPCTPriceOracle} from "../src/interfaces/ISPCTPriceOracle.sol";

contract DeployWUSDTestnet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        address endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        uint24 cdPeriod = 300;
        IERC20 usdc = IERC20(0xB1d7B2e0597Bac1f4335ecB437Bf8277e478B978);
        ISPCTPool spct = ISPCTPool(0xa524f70eA27e24EB3011C4A7C361a53dD42f4890);
        ISPCTPriceOracle oracle = ISPCTPriceOracle(0xCa593b4429E4Ed86D26C8202593Ab85d617E73C1);
        
        vm.startBroadcast(deployerPrivateKey);
        wUSD _wusd = new wUSD(admin, endpoint, usdc, spct, oracle, cdPeriod);
        _wusd.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_wusd)
        );
    }
}

contract Interaction is Script {
    function deposit(address _wusd, address receiver, uint256 _amount) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        wUSD(payable(_wusd)).deposit(receiver,_amount);
        vm.stopBroadcast();
    }

    function depositSPCT(address _wusd, uint256 _amount) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        wUSD(payable(_wusd)).depositBySPCT(_amount);
        vm.stopBroadcast();
    }

    function redeem(address _wusd, uint256 _amount) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        wUSD(payable(_wusd)).cdRedeem(_amount);
        vm.stopBroadcast();
    }
}
