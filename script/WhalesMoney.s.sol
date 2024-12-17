// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console2} from "forge-std/console2.sol";
import {wUSD} from "../src/core/wUSD.sol";
import {swUSD} from "../src/core/swUSD.sol";
import {wUSDFlat} from "../src/core/wUSDFlat.sol";
import {SPCTPool} from "../src/core/SPCTPool.sol";
import {SPCTPriceOracle} from "../src/core/oracle/SPCTPriceOracle.sol";
import {ISPCTPool} from "../src/interfaces/ISPCTPool.sol";
import {ISPCTPriceOracle} from "../src/interfaces/ISPCTPriceOracle.sol";
import {RewardDistributor} from "../src/core/RewardDistributor.sol";
import {swUSDwUSDExchangeRateChainlinkAdapter} from "../src/core/oracle/swUSDwUSDExchangeRateChainlinkAdapter.sol";

contract DeployWhalesMoneyTestnet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = 0x9E2581389736e76f0A02c4EADcFa6209464eec91;
        address feeRecipient = 0x999De76B7A22dF77e6873f22aA178D76Fc86fC87;
        address treasury = 0xDAF7448C9D7598fAB194F43907CCCb7fB2C03df4;
        address endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        IERC20 usdc = IERC20(0xfbAD9B8FfCD9ab6325b2d50B8b8a12F7546AC776);
        uint24 cdPeriod = 300;
       
        vm.startBroadcast(deployerPrivateKey);
        // Oracle
        SPCTPriceOracle _oracle = new SPCTPriceOracle();
        // SPCTPool
        SPCTPool _spctPool = new SPCTPool(admin);
        _spctPool.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _spctPool.setFeeRecipient(feeRecipient);
        // wUSD
        wUSD _wusd = new wUSD(admin, endpoint, usdc, ISPCTPool(address(_spctPool)), ISPCTPriceOracle(address(_oracle)), cdPeriod);
        _wusd.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _wusd.setFeeRecipient(feeRecipient);
        _wusd.setTreasury(treasury);
        // swUSD
        swUSD _swusd = new swUSD(admin, IERC20(address(_wusd)), cdPeriod);
        _swusd.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _swusd.grantRole(keccak256("YIELD_MANAGER_ROLE"), admin);
        // Add to whitelist
        _spctPool.addToWhitelist(address(_wusd));
        _spctPool.addToWhitelist(feeRecipient);
        _spctPool.setwUSDAddress(address(_wusd));
        // Reward Distributor
        RewardDistributor _rewardDistributor = new RewardDistributor(address(_wusd), address(_swusd));
        _swusd.grantRole(keccak256("YIELD_MANAGER_ROLE"), address(_rewardDistributor));
        swUSDwUSDExchangeRateChainlinkAdapter _swUSDOrcale = new swUSDwUSDExchangeRateChainlinkAdapter(address(_swusd)); 
        vm.stopBroadcast();

        console2.log("Orcale deployed on with address: ", address(_oracle));
        console2.log("SPCTPool deployed on with address: ", address(_spctPool));
        console2.log("WUSD deployed on with address: ", address(_wusd));
        console2.log("sWUSD deployed on with address: ", address(_swusd));
        console2.log("RewardDistributor deployed on with address: ", address(_rewardDistributor));
        console2.log("swUSD Oracle deployed on with address: ", address(_swUSDOrcale));
    }   
}
