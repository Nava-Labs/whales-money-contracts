// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { USDb } from "../src/v1/USDb.sol";
import { SUSDb } from "../src/v1/sUSDb.sol";
import { SPCTPool } from "../src/v1/SPCTPool.sol";
import { SPCTPriceOracle } from "../src/v1/SPCTPriceOracle.sol";
import { StandardToken } from "../src/Mock/MockToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISPCTPool } from "../interfaces/ISPCTPool.sol";
import { ISPCTPriceOracle } from "../interfaces/ISPCTPriceOracle.sol";

import "../src/utils/SafeMath.sol";

contract UsdbTest is StdCheats, Test {
  using SafeMath for uint256;
  USDb internal usdb;
  SUSDb internal susdb;
  SPCTPool internal spct;
  SPCTPriceOracle internal oracle;

  StandardToken private usdc;

  // Owner
  address public constant owner = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
  address manager = address(0x002b);
  address feeRecipient = address(0x006f);

  // User
  address alice = address(0x003c);
  address bobby = address(0x004d);
  address charl = address(0x005e);

  function setUp() public virtual {
    vm.createSelectFork({urlOrAlias: "arbitrumSepolia", blockNumber: 85_204_649});
    // Deploy Token
    vm.startPrank(owner);

    usdc = new StandardToken("USDC", "USDC",  6, 1000000 ether);

    // Distribute Token
    usdc.transfer(alice, _convertToDecimals6(100 ether));
    usdc.transfer(bobby, _convertToDecimals6(100 ether));
    usdc.transfer(charl, _convertToDecimals6(100 ether));
    usdc.transfer(manager, _convertToDecimals6(10_000 ether));

    // Deploy Oracle
    oracle = new SPCTPriceOracle();

    // Deploy SPCTPool
    spct = new SPCTPool(owner, IERC20(address(usdc)));

    // Deploy USDB
    address endpointLayerZero = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    usdb = new USDb(owner, endpointLayerZero, IERC20(address(usdc)), ISPCTPool(address(spct)), ISPCTPriceOracle(address(oracle)));
    // Deploy sUSDB
    uint24 CDPeriod = 3 days;
    susdb = new SUSDb(owner, IERC20(address(usdb)), CDPeriod);

    // Grant Role
    spct.grantRole(spct.POOL_MANAGER_ROLE(), manager);
    usdb.grantRole(usdb.POOL_MANAGER_ROLE(), manager);
    susdb.grantRole(susdb.YIELD_MANAGER_ROLE(), manager);
    susdb.grantRole(susdb.POOL_MANAGER_ROLE(), manager);

    vm.stopPrank();

    // whitelist
    vm.startPrank(manager);
    spct.addToWhitelist(address(usdb));
    vm.stopPrank();
  }

  function testUsdbMintRedeemSuccess() public {
    // Mint usdb
    _mintUSDb(alice, _convertToDecimals6(100 ether));
    _mintUSDb(bobby, _convertToDecimals6(100 ether));
    _mintUSDb(charl, _convertToDecimals6(100 ether));
    
    // check balance usdb
    assertEq(usdb.balanceOf(alice), 100 ether);
    assertEq(usdb.balanceOf(bobby), 100 ether);
    assertEq(usdb.balanceOf(charl), 100 ether);

    // spct pool balance in usdb
    assertEq(spct.balanceOf(address(usdb)), 300 ether);

    // usdc balance in spct
    assertEq(usdc.balanceOf(address(spct)), _convertToDecimals6(300 ether));

    vm.warp(block.timestamp + 1 days);

    // redeem usdb
    _redeemUSDb(alice, 100 ether);
    _redeemUSDb(bobby, 100 ether);
    _redeemUSDb(charl, 100 ether);

    // check balance usdb
    assertEq(usdb.balanceOf(alice), 0 ether);
    assertEq(usdb.balanceOf(bobby), 0 ether);
    assertEq(usdb.balanceOf(charl), 0 ether);

    // spct pool balance in usdb
    assertEq(spct.balanceOf(address(usdb)), 0 ether); 
  }

  function testUsdbMintRedeemWithUsdbFee() public {
    vm.startPrank(manager);
    usdb.setMintFeeRate(100000);
    usdb.setRedeemFeeRate(100000);
    usdb.setFeeRecipient(feeRecipient);
    vm.stopPrank();

    // Mint usdb
    uint256 aliceMinted = 100 ether;
    uint256 aliceMintedInDecimals6 = _convertToDecimals6(aliceMinted);
    _mintUSDb(alice, aliceMintedInDecimals6);

    // check balance usdb
    uint256 convertToSPCT = aliceMintedInDecimals6.mul(1e12);
    uint256 feeAmount = convertToSPCT.mul(usdb.mintFeeRate()).div(usdb.FEE_COEFFICIENT());
    uint256 aliceBalanceAfterFee = convertToSPCT.sub(feeAmount);
    // alice get usdb minus fee
    assertEq(usdb.balanceOf(alice), aliceBalanceAfterFee);
    // feeRecipient get fee in usdb
    assertEq(usdb.balanceOf(feeRecipient), feeAmount);
    // usdb store spct full amount
    assertEq(spct.balanceOf(address(usdb)), convertToSPCT);
    // usdc balance in spct
    assertEq(usdc.balanceOf(address(spct)), aliceMintedInDecimals6);

    vm.warp(block.timestamp + 1 days);

    // redeem usdb
    _redeemUSDb(alice, aliceBalanceAfterFee);

    uint256 redeemFeeAmount = aliceBalanceAfterFee.mul(usdb.redeemFeeRate()).div(usdb.FEE_COEFFICIENT());
    uint256 aliceBalanceAfterRedeemFee = aliceBalanceAfterFee.sub(redeemFeeAmount);
    uint256 convertToUSDC = aliceBalanceAfterRedeemFee.div(1e12);
    // alice burn usdb minus fee
    assertEq(usdb.balanceOf(alice), 0 ether);
    // feeRecipient get fee in usdb
    assertEq(usdb.balanceOf(feeRecipient), feeAmount + redeemFeeAmount);
    // spct pool balance in usdb
    assertEq(spct.balanceOf(address(usdb)), convertToSPCT - aliceBalanceAfterRedeemFee);
    // alice get usdc
    assertEq(usdc.balanceOf(alice), convertToUSDC);
    // usdc balance in spct
    assertEq(usdc.balanceOf(address(spct)), (convertToSPCT - aliceBalanceAfterRedeemFee).div(1e12));
  }

  function testUsdbMintRedeemWithSPCTFee() public {
    vm.startPrank(manager);
    spct.addToWhitelist(feeRecipient);
    spct.setMintFeeRate(100000);
    spct.setRedeemFeeRate(100000);
    spct.setFeeRecipient(feeRecipient);
    vm.stopPrank();

    // Mint usdb
    uint256 aliceMinted = 100 ether;
    uint256 aliceMintedInDecimals6 = _convertToDecimals6(aliceMinted);
    _mintUSDb(alice, aliceMintedInDecimals6);

    // check balance usdb
    uint256 convertToSPCT = aliceMintedInDecimals6.mul(1e12);
    uint256 spctFeeAmount = convertToSPCT.mul(spct.mintFeeRate()).div(usdb.FEE_COEFFICIENT());
    uint256 aliceBalanceAfterFee = convertToSPCT.sub(spctFeeAmount);
    // alice get usdb minus fee
    assertEq(usdb.balanceOf(alice), aliceBalanceAfterFee);
    // feeRecipient get fee in usdb
    assertEq(spct.balanceOf(feeRecipient), spctFeeAmount);
    // usdb store spct - fee amount
    assertEq(spct.balanceOf(address(usdb)), aliceBalanceAfterFee);
    // usdc balance in spct
    assertEq(usdc.balanceOf(address(spct)), aliceMintedInDecimals6);

    vm.warp(block.timestamp + 1 days);

    // redeem usdb
    _redeemUSDb(alice, aliceBalanceAfterFee);

    uint256 spctRedeemFeeAmount = aliceBalanceAfterFee.mul(spct.redeemFeeRate()).div(usdb.FEE_COEFFICIENT());
    uint256 aliceBalanceAfterRedeemFee = aliceBalanceAfterFee.sub(spctRedeemFeeAmount);
    uint256 convertToUSDC = aliceBalanceAfterRedeemFee.div(1e12);
    // alice burn usdb minus fee
    assertEq(usdb.balanceOf(alice), 0 ether);
    // feeRecipient get fee in usdb
    assertEq(spct.balanceOf(feeRecipient), spctFeeAmount + spctRedeemFeeAmount);
    // spct pool balance in usdb
    assertEq(spct.balanceOf(address(usdb)), 0 ether);
    // alice get usdc
    assertEq(usdc.balanceOf(alice), convertToUSDC);
    // usdc balance in spct
    assertEq(usdc.balanceOf(address(spct)), (convertToSPCT - aliceBalanceAfterRedeemFee).div(1e12));

  }

  function testUsdbMintWithBothFee() public {
    vm.startPrank(manager);
    // usdb
    usdb.setMintFeeRate(1000000);
    usdb.setRedeemFeeRate(1000000);
    usdb.setFeeRecipient(feeRecipient);
    // spct
    spct.addToWhitelist(feeRecipient);
    spct.setMintFeeRate(1000000);
    spct.setRedeemFeeRate(1000000);
    spct.setFeeRecipient(feeRecipient);
    vm.stopPrank();
    
     // Mint usdb
    uint256 aliceMinted = 100 ether;
    uint256 aliceMintedInDecimals6 = _convertToDecimals6(aliceMinted);
    _mintUSDb(alice, aliceMintedInDecimals6);

    // check balance usdb
    uint256 convertToSPCT = aliceMintedInDecimals6.mul(1e12);
    // spct fee
    uint256 spctFeeAmount = convertToSPCT.mul(spct.mintFeeRate()).div(usdb.FEE_COEFFICIENT());
    uint256 spctAmountAfterFee = convertToSPCT.sub(spctFeeAmount);
    // usdb fee
    uint256 feeAmount = spctAmountAfterFee.mul(usdb.mintFeeRate()).div(usdb.FEE_COEFFICIENT());
    uint256 amountAfterFee = spctAmountAfterFee.sub(feeAmount);
    // check usdb balance
    assertEq(usdb.balanceOf(alice), amountAfterFee);
    assertEq(usdb.balanceOf(feeRecipient), feeAmount);
    // check spct balance
    assertEq(spct.balanceOf(feeRecipient), spctFeeAmount);
    assertEq(spct.balanceOf(address(usdb)), spctAmountAfterFee);
    // usdc balance in spct
    assertEq(usdc.balanceOf(address(spct)), aliceMintedInDecimals6);

    vm.warp(block.timestamp + 1 days);

    // redeem usdb
    _redeemUSDb(alice, amountAfterFee);

    uint256 usdbRedeemFeeAmount = amountAfterFee.mul(usdb.redeemFeeRate()).div(usdb.FEE_COEFFICIENT());
    uint256 amountAfterRedeemFee = amountAfterFee.sub(usdbRedeemFeeAmount);
    uint256 spctRedeemFeeAmount = amountAfterRedeemFee.mul(spct.redeemFeeRate()).div(usdb.FEE_COEFFICIENT());
    uint256 amountAfterRedeemSPCTFee = amountAfterRedeemFee.sub(spctRedeemFeeAmount);
    uint256 convertToUSDC = amountAfterRedeemSPCTFee.div(1e12);
     // alice burn usdb minus fee
    assertEq(usdb.balanceOf(alice), 0 ether);
    // feeRecipient get fee in usdb
    assertEq(usdb.balanceOf(feeRecipient), feeAmount + usdbRedeemFeeAmount);
    // feeRecipient get fee in spct
    assertEq(spct.balanceOf(feeRecipient), spctFeeAmount + spctRedeemFeeAmount);
    // alice get usdc
    assertEq(usdc.balanceOf(alice), convertToUSDC);
    // spct pool balance in usdb
    uint256 expectedSPCTBalanceInUSDb = spctAmountAfterFee.sub(amountAfterRedeemFee);
    assertEq(spct.balanceOf(address(usdb)), expectedSPCTBalanceInUSDb);
    // usdc balance in spct
    uint256 expectedUSDCBalanceInSPCT = aliceMintedInDecimals6.sub(convertToUSDC);
    assertEq(usdc.balanceOf(address(spct)), expectedUSDCBalanceInSPCT);
    
  } 

  function testSpctDepositByFiatAndUsdbDepositBySPCT() public {
    // deposit by fiat
    vm.startPrank(manager);
    spct.addToWhitelist(alice);
    spct.depositByFiat(alice, 100 ether);
    vm.stopPrank();

    assertEq(spct.balanceOf(alice), 100 ether);

    // deposit by spct
    vm.startPrank(alice);
    spct.approve(address(usdb), type(uint256).max);
    usdb.depositBySPCT(100 ether);
    vm.stopPrank();

    assertEq(spct.balanceOf(address(usdb)), 100 ether);
    assertEq(spct.balanceOf(alice), 0 ether);
    assertEq(usdb.balanceOf(alice), 100 ether);

    vm.warp(block.timestamp + 1 days);

    vm.startPrank(alice);
    usdb.redeemBackSPCT(100 ether);
    vm.stopPrank();

    assertEq(spct.balanceOf(address(usdb)), 0 ether);
    assertEq(spct.balanceOf(alice), 100 ether);
    assertEq(usdb.balanceOf(alice), 0 ether);

    vm.startPrank(manager);
    spct.redeemByFiat(alice, 100 ether);
    vm.stopPrank();

    assertEq(spct.balanceOf(alice), 0 ether);
    assertEq(spct.balanceOf(address(usdb)), 0 ether);
  }

  function testStackingSuccess() public {
    // mint usdb
    uint256 mintValue = 100 ether;
    uint256 mintValueInDecimals6 = _convertToDecimals6(mintValue);
    // alice will get full yield
    _mintUSDb(alice, mintValueInDecimals6);
    // bob will get half yield
    _mintUSDb(bobby, mintValueInDecimals6);

    assertEq(usdb.balanceOf(alice), mintValue);
    assertEq(usdb.balanceOf(bobby), mintValue);

    // alice and bobby stake usdb
    _stakeUsdb(alice, mintValue);
    _stakeUsdb(bobby, mintValue);

    assertEq(usdb.balanceOf(alice), 0);
    assertEq(usdb.balanceOf(bobby), 0);

    assertEq(susdb.balanceOf(alice), mintValue);
    assertEq(susdb.balanceOf(bobby), mintValue);
    
    // check if manager didn't add yield will value change
    vm.warp(block.timestamp + 10 days);
    assertEq(susdb.balanceOf(alice), mintValue);
    assertEq(susdb.balanceOf(bobby), mintValue);

    // unstake following cooldown period
    vm.startPrank(alice);
    susdb.CDAssets(mintValue);
    vm.stopPrank();

    vm.warp(block.timestamp + 1 days);
    vm.startPrank(alice);
    vm.expectRevert("UNSTAKE_FAILED");
    susdb.unstake();
    vm.stopPrank();

    // unstake
    vm.warp(block.timestamp + 3 days);
    vm.startPrank(alice);
    susdb.unstake();
    vm.stopPrank();

    assertEq(susdb.balanceOf(alice), 0);
    assertEq(usdb.balanceOf(alice), mintValue);
  }

  function testStackingSuccessAndYield() public {
    // manager mint usdb for yield
    uint256 managerMintValue = 1000 ether;
    _mintUSDb(manager, _convertToDecimals6(managerMintValue));

    // set yield period
    vm.startPrank(manager);
    uint256 vestingPeriod = 10 days;
    susdb.setNewVestingPeriod(vestingPeriod);
    vm.stopPrank();

    // alice will stake before vesting period
    uint256 aliceMintValue = 100 ether;
    uint256 aliceMintValueInDecimals6 = _convertToDecimals6(aliceMintValue);
    _mintUSDb(alice, aliceMintValueInDecimals6);
    assertEq(usdb.balanceOf(alice), aliceMintValue);
    // bobby will stake 5 days after vesting period
    uint256 bobbyMintValue = 100 ether;
    uint256 bobbyMintValueInDecimals6 = _convertToDecimals6(bobbyMintValue);
    _mintUSDb(bobby, bobbyMintValueInDecimals6);
    assertEq(usdb.balanceOf(bobby), bobbyMintValue);

    // -------- Start Stacking --------
    // alice stake usdb
    _stakeUsdb(alice, aliceMintValue);
    assertEq(usdb.balanceOf(alice), 0);
    assertEq(susdb.balanceOf(alice), aliceMintValue);

    // manager add yield
    vm.warp(block.timestamp + 1 days);
    vm.startPrank(manager);
    usdb.approve(address(susdb), type(uint256).max);
    uint256 yieldVestingAmount = 100 ether;
    susdb.addYield(yieldVestingAmount);
    assertEq(usdb.balanceOf(address(susdb)), yieldVestingAmount.add(aliceMintValue));
    vm.stopPrank();

    // check alice after 1 day of vesting period end
    vm.warp(block.timestamp + 1 days);
    uint256 totalAssets = aliceMintValue.add(yieldVestingAmount); // 200 ether
    uint256 elapsedTime = 1 days;
    uint256 unvestedAmount = yieldVestingAmount.mul(vestingPeriod - elapsedTime).div(vestingPeriod);
    uint256 vestedAssets = totalAssets.sub(unvestedAmount);

    // Calculate expected assets (USDb) for Alice's shares
    uint256 expectedAssets = vestedAssets.mul(aliceMintValue).div(aliceMintValue); // Alice has 100% of shares
    assertApproxEqAbs(susdb.convertToAssets(aliceMintValue), expectedAssets, 1); // use this because of rounding issue

    // Calculate expected shares (sUSDb) for Alice's assets
    uint256 expectedShares = aliceMintValue.mul(aliceMintValue).div(vestedAssets);
    assertApproxEqAbs(susdb.convertToShares(aliceMintValue), expectedShares, 1);

    // check alice after 4 days of vesting period end
    vm.warp(block.timestamp + 3 days);

    uint256 aliceSharesBefore = susdb.balanceOf(alice);
    uint256 aliceAssetsBefore = susdb.convertToAssets(aliceSharesBefore);

    _stakeUsdb(bobby, bobbyMintValue);

    uint256 bobbyShares = susdb.balanceOf(bobby);

    // Recalculate Alice's assets after Bobby's stake
    uint256 aliceAssetsAfter = susdb.convertToAssets(aliceSharesBefore);

    // Assert that Alice's assets have increased due to yield
    assert(aliceAssetsAfter > aliceAssetsBefore);

    // Assert that Bobby's shares are less than his initial stake due to the increased asset-to-share ratio
    assert(bobbyShares < bobbyMintValue);

    // check alice & bobby after 5 days of vesting period end
    vm.warp(block.timestamp + 1 days);

    uint256 totalShares = susdb.totalSupply();
    uint256 totalAssetsAfter5Days = susdb.totalAssets();

    // Recalculate expected assets for Alice and Bobby
    uint256 aliceExpectedAssets = totalAssetsAfter5Days.mul(aliceSharesBefore).div(totalShares);
    uint256 bobbyExpectedAssets = totalAssetsAfter5Days.mul(bobbyShares).div(totalShares);

    assertApproxEqAbs(susdb.convertToAssets(aliceSharesBefore), aliceExpectedAssets, 1e15); // 0.001 USDb tolerance
    assertApproxEqAbs(susdb.convertToAssets(bobbyShares), bobbyExpectedAssets, 1e15); // 0.001 USDb tolerance

    // Calculate expected shares for Alice's and Bobby's assets
    uint256 aliceExpectedShares = aliceExpectedAssets.mul(totalShares).div(totalAssetsAfter5Days);
    uint256 bobbyExpectedShares = bobbyExpectedAssets.mul(totalShares).div(totalAssetsAfter5Days);

    assertApproxEqAbs(susdb.convertToShares(aliceExpectedAssets), aliceExpectedShares, 1); // 1 wei tolerance
    assertApproxEqAbs(susdb.convertToShares(bobbyExpectedAssets), bobbyExpectedShares, 1); // 1 wei tolerance

    // vesting period end
    vm.warp(block.timestamp + 5 days);

    // At this point, it's been 10 days since the yield was added
    // The entire yield should be vested now

    // Calculate final assets and shares for Alice and Bobby
    uint256 finalTotalAssets = susdb.totalAssets();
    uint256 finalTotalShares = susdb.totalSupply();

    uint256 aliceFinalShares = susdb.balanceOf(alice);
    uint256 bobbyFinalShares = susdb.balanceOf(bobby);

    uint256 aliceFinalAssets = susdb.convertToAssets(aliceFinalShares);
    uint256 bobbyFinalAssets = susdb.convertToAssets(bobbyFinalShares);

    // Calculate expected final assets
    uint256 expectedTotalAssets = aliceMintValue.add(bobbyMintValue).add(yieldVestingAmount);

    // Assert that the total assets match the expected amount
    assertEq(finalTotalAssets, expectedTotalAssets, "Total assets should match expected amount after full vesting");

    // Calculate and assert Alice's final assets
    uint256 aliceExpectedFinalAssets = expectedTotalAssets.mul(aliceFinalShares).div(finalTotalShares);
    assertApproxEqAbs(aliceFinalAssets, aliceExpectedFinalAssets, 1e15, "Alice's final assets should match expected amount");

    // Calculate and assert Bobby's final assets
    uint256 bobbyExpectedFinalAssets = expectedTotalAssets.mul(bobbyFinalShares).div(finalTotalShares);
    assertApproxEqAbs(bobbyFinalAssets, bobbyExpectedFinalAssets, 1e15, "Bobby's final assets should match expected amount");

    // Assert that Alice's assets have increased due to yield
    require(aliceFinalAssets > aliceMintValue, "Alice's assets should have increased due to yield");

    // Assert that Bobby's assets have increased due to yield
    require(bobbyFinalAssets > bobbyMintValue, "Bobby's assets should have increased due to yield");

    // Calculate the yield earned by Alice and Bobby
    uint256 aliceYieldEarned = aliceFinalAssets.sub(aliceMintValue);
    uint256 bobbyYieldEarned = bobbyFinalAssets.sub(bobbyMintValue);

    // Assert that the total yield distributed matches the original yield amount
    uint256 totalYieldDistributed = aliceYieldEarned.add(bobbyYieldEarned);
    assertApproxEqAbs(totalYieldDistributed, yieldVestingAmount, 1e15, "Total yield distributed should match the original yield amount");

    // -------- Unstaking --------
    // Alice unstakes
    vm.startPrank(alice);
    uint256 aliceFullBalance = aliceMintValue.add(aliceYieldEarned);
    susdb.CDAssets(aliceFullBalance);
    vm.stopPrank();

    // Bobby unstakes
    vm.startPrank(bobby);
    uint256 bobbyFullBalance = bobbyMintValue.add(bobbyYieldEarned);
    susdb.CDAssets(bobbyFullBalance);
    vm.stopPrank();

    // Wait for the cooldown period
    vm.warp(block.timestamp + 3 days);

    // Alice completes unstaking
    vm.startPrank(alice);
    susdb.unstake();
    vm.stopPrank();

    // Bobby completes unstaking
    vm.startPrank(bobby);
    susdb.unstake();
    vm.stopPrank();
    
    // Assert that sUSDb balances are now zero
    assertEq(susdb.balanceOf(alice), 0, "Alice's sUSDb balance should be zero after unstaking");
    assertEq(susdb.balanceOf(bobby), 0, "Bobby's sUSDb balance should be zero after unstaking");

    // Assert that the total supply of sUSDb is now zero (or very close to zero due to potential rounding)
    assertApproxEqAbs(susdb.totalSupply(), 0, 1, "Total supply of sUSDb should be zero after all unstaking");

    // Assert that the total assets in sUSDb contract is now zero (or very close to zero)
    assertApproxEqAbs(susdb.totalAssets(), 0, 1e15, "Total assets in sUSDb should be zero after all unstaking");
  }

  // for easier read the test
  function _convertToDecimals6(uint256 _amount) internal pure returns (uint256) {
    return _amount / 10**12;
  }

  function _mintUSDb(address _who, uint256 _amount) internal {
    vm.startPrank(_who);
    usdc.approve(address(usdb), type(uint256).max);
    usdb.deposit(_amount);
    vm.stopPrank();
  }

  function _redeemUSDb(address _who, uint256 _amount) internal {
    vm.startPrank(_who);
    usdb.redeem(_amount);
    vm.stopPrank();
  }

  function _stakeUsdb(address _who, uint256 _amount) internal {
    vm.startPrank(_who);
    usdb.approve(address(susdb), type(uint256).max);
    susdb.deposit(_amount, _who);
    vm.stopPrank();
  }


}