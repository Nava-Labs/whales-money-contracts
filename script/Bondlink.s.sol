// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console2 } from "forge-std/console2.sol";
import { USDb } from "../src/v1/USDb.sol";
import { SUSDb } from "../src/v1/sUSDb.sol";
import { USDbFlat } from "../src/v1/USDbFlat.sol";
import { SPCTPool } from "../src/v1/SPCTPool.sol";
import { SPCTPriceOracle } from "../src/v1/SPCTPriceOracle.sol";
import "../interfaces/ISPCTPool.sol";
import "../interfaces/ISPCTPriceOracle.sol";

contract DeployBondlinkTestnet is Script {
    function launch() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        address feeRecipient = 0x68E76Ec846501527d08B27BC9259b70f5E590AF6;
        address endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        IERC20 usdc = IERC20(0x0fbbE1770F92eD1ef5B951d575cE81B6F80bBeb2);
        uint24 cdPeriod = 300;
       
        vm.startBroadcast(deployerPrivateKey);
        // Oracle
        SPCTPriceOracle _oracle = new SPCTPriceOracle();
        // SPCTPool
        SPCTPool _spctPool = new SPCTPool(admin, usdc);
        _spctPool.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _spctPool.setFeeRecipient(feeRecipient);
        // USDb
        USDb _usdb = new USDb(admin, endpoint, usdc, ISPCTPool(address(_spctPool)), ISPCTPriceOracle(address(_oracle)));
        _usdb.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _usdb.setFeeRecipient(feeRecipient);
        // sUSDb
        SUSDb _susdb = new SUSDb(admin, IERC20(address(_usdb)), cdPeriod);
        _susdb.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _susdb.grantRole(keccak256("YIELD_MANAGER_ROLE"), admin);
        // Add to whitelist
        _spctPool.addToWhitelist(address(_usdb));

        vm.stopBroadcast();

        console.log(
            "contract deployed on with address: ",
            address(_oracle)
        );

        console.log(
            "contract deployed on with address: ",
            address(_spctPool)
        );

        console.log(
            "contract deployed on with address: ",
            address(_usdb)
        );

        console.log(
            "contract deployed on with address: ",
            address(_susdb)
        );
    }
}