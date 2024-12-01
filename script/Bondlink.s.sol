// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console2} from "forge-std/console2.sol";
import {USDb} from "../src/core/USDb.sol";
import {sUSDb} from "../src/core/sUSDb.sol";
import {USDbFlat} from "../src/core/USDbFlat.sol";
import {SPCTPool} from "../src/core/SPCTPool.sol";
import {SPCTPriceOracle} from "../src/core/oracle/SPCTPriceOracle.sol";
import {ISPCTPool} from "../src/interfaces/ISPCTPool.sol";
import {ISPCTPriceOracle} from "../src/interfaces/ISPCTPriceOracle.sol";
import {RewardDistributor} from "../src/core/RewardDistributor.sol";
import {sUSDbUSDbExchangeRateChainlinkAdapter} from "../src/core/oracle/sUSDbUSDbExchangeRateChainlinkAdapter.sol";

contract DeployBondlinkTestnet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        address feeRecipient = 0x68E76Ec846501527d08B27BC9259b70f5E590AF6;
        address treasury = 0x904275b0bB34dc3d48A05ae65DF0Bdeb825E751f;
        address endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        address signerAddress = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        IERC20 usdc = IERC20(0x0fbbE1770F92eD1ef5B951d575cE81B6F80bBeb2);
        uint24 cdPeriod = 300;
       
        vm.startBroadcast(deployerPrivateKey);
        // Oracle
        SPCTPriceOracle _oracle = new SPCTPriceOracle();
        // SPCTPool
        SPCTPool _spctPool = new SPCTPool(admin);
        _spctPool.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _spctPool.setFeeRecipient(feeRecipient);
        // USDb
        USDb _usdb = new USDb(admin, endpoint, usdc, ISPCTPool(address(_spctPool)), ISPCTPriceOracle(address(_oracle)), cdPeriod, signerAddress);
        _usdb.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _usdb.setFeeRecipient(feeRecipient);
        _usdb.setTreasury(treasury);
        // sUSDb
        sUSDb _susdb = new sUSDb(admin, IERC20(address(_usdb)), cdPeriod);
        _susdb.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _susdb.grantRole(keccak256("YIELD_MANAGER_ROLE"), admin);
        // Add to whitelist
        _spctPool.addToWhitelist(address(_usdb));
        _spctPool.addToWhitelist(feeRecipient);
        _spctPool.setUsdbAddress(address(_usdb));
        // Reward Distributor
        RewardDistributor _rewardDistributor = new RewardDistributor(address(_usdb), address(_susdb));
        _susdb.grantRole(keccak256("YIELD_MANAGER_ROLE"), address(_rewardDistributor));
        sUSDbUSDbExchangeRateChainlinkAdapter _sUSDbOrcale = new sUSDbUSDbExchangeRateChainlinkAdapter(address(_susdb)); 
        vm.stopBroadcast();

        console2.log("Orcale deployed on with address: ", address(_oracle));
        console2.log("SPCTPool deployed on with address: ", address(_spctPool));
        console2.log("USDB deployed on with address: ", address(_usdb));
        console2.log("sUSDB deployed on with address: ", address(_susdb));
        console2.log("RewardDistributor deployed on with address: ", address(_rewardDistributor));
        console2.log("sUSDb Oracle deployed on with address: ", address(_sUSDbOrcale));
    }   
}
