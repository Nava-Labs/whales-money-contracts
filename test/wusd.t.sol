// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {wUSD} from "../src/core/wUSD.sol";
import {swUSD} from "../src/core/swUSD.sol";
import {SPCTPool} from "../src/core/SPCTPool.sol";
import {SPCTPriceOracle} from "../src/core/oracle/SPCTPriceOracle.sol";
import {StandardToken} from "../src/Mock/MockToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISPCTPool} from "../src/interfaces/ISPCTPool.sol";
import {ISPCTPriceOracle} from "../src/interfaces/ISPCTPriceOracle.sol";

import {SafeMath} from "../src/utils/SafeMath.sol";

contract WUSDTest is StdCheats, Test {
  using SafeMath for uint256;

  wUSD internal wusd;
  swUSD internal swusd;
  SPCTPool internal spct;
  SPCTPriceOracle internal oracle;

  StandardToken private usdc;

  // Owner
  address public constant owner = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
  address manager = address(0x002b);
  address feeRecipient = address(0x006f);
  address treasury = address(0x007fa);

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
    spct = new SPCTPool(owner);

    // Deploy WUSD
    uint24 CDPeriod = 3 days;
    address endpointLayerZero = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    wusd = new wUSD(owner, endpointLayerZero, IERC20(address(usdc)), ISPCTPool(address(spct)), ISPCTPriceOracle(address(oracle)), CDPeriod);
    // Deploy sWUSD
    swusd = new swUSD(owner, IERC20(address(wusd)), CDPeriod);

    // Grant Role
    spct.grantRole(spct.POOL_MANAGER_ROLE(), manager);
    wusd.grantRole(wusd.POOL_MANAGER_ROLE(), manager);
    swusd.grantRole(swusd.YIELD_MANAGER_ROLE(), manager);
    swusd.grantRole(swusd.POOL_MANAGER_ROLE(), manager);

    vm.stopPrank();

    // whitelist
    vm.startPrank(manager);
    wusd.setTreasury(treasury);
    spct.addToWhitelist(address(wusd));
    spct.setwUSDAddress(address(wusd));
    vm.stopPrank();
  }

  function testwUSDMintRedeemSuccess() public {
    // Mint wusd
    _mintwUSD(alice, _convertToDecimals6(100 ether));
    _mintwUSD(bobby, _convertToDecimals6(100 ether));
    _mintwUSD(charl, _convertToDecimals6(100 ether));

    // check balance usdc
    assertEq(usdc.balanceOf(alice), 0);
    assertEq(usdc.balanceOf(bobby), 0);
    assertEq(usdc.balanceOf(charl), 0);

    // check balance wusd
    assertEq(wusd.balanceOf(alice), 100 ether);
    assertEq(wusd.balanceOf(bobby), 100 ether);
    assertEq(wusd.balanceOf(charl), 100 ether);

    // spct pool balance in wusd
    assertEq(spct.balanceOf(address(wusd)), 300 ether);

   // check balance treasury
    assertEq(usdc.balanceOf(treasury), _convertToDecimals6(300 ether));

    vm.warp(block.timestamp + 1 days);

    // redeem wusd
    _cdRedeemwUSD(alice, 100 ether);
    _cdRedeemwUSD(bobby, 100 ether);
    _cdRedeemwUSD(charl, 100 ether);

    // check balance wusd
    assertEq(wusd.balanceOf(alice), 0 ether);
    assertEq(wusd.balanceOf(bobby), 0 ether);
    assertEq(wusd.balanceOf(charl), 0 ether);

    // check balance usdc
    assertEq(usdc.balanceOf(alice), 0);
    assertEq(usdc.balanceOf(bobby), 0);
    assertEq(usdc.balanceOf(charl), 0);

    vm.warp(block.timestamp + 3 days);

    // treasury must transfer usdc to wusd before user redeem cd period ends
    vm.startPrank(treasury);
    usdc.approve(address(wusd), _convertToDecimals6(300 ether));
    usdc.transfer(address(wusd), _convertToDecimals6(300 ether));
    vm.stopPrank();

    // redeem wusd
    _redeemwUSD(alice);
    _redeemwUSD(bobby);
    _redeemwUSD(charl);

    // check balance usdc
    assertEq(usdc.balanceOf(alice), _convertToDecimals6(100 ether));
    assertEq(usdc.balanceOf(bobby), _convertToDecimals6(100 ether));
    assertEq(usdc.balanceOf(charl), _convertToDecimals6(100 ether));
  }

  function testwUSDMintRedeemWithwUSDFee() public {
    vm.startPrank(manager);
    wusd.setMintFeeRate(100000);
    wusd.setRedeemFeeRate(100000);
    wusd.setFeeRecipient(feeRecipient);
    vm.stopPrank();

    // Mint wusd
    uint256 aliceMinted = 100 ether;
    uint256 aliceMintedInDecimals6 = _convertToDecimals6(aliceMinted);
    _mintwUSD(alice, aliceMintedInDecimals6);

    // check balance wusd
    uint256 convertToSPCT = aliceMintedInDecimals6.mul(1e12);
    uint256 feeAmount = convertToSPCT.mul(wusd.mintFeeRate()).div(wusd.FEE_COEFFICIENT());
    uint256 aliceBalanceAfterFee = convertToSPCT.sub(feeAmount);
    // alice get wusd minus fee
    assertEq(wusd.balanceOf(alice), aliceBalanceAfterFee);
    // feeRecipient get fee in wusd
    assertEq(wusd.balanceOf(feeRecipient), feeAmount);
    // wusd store spct full amount
    assertEq(spct.balanceOf(address(wusd)), convertToSPCT);

    vm.warp(block.timestamp + 1 days);

    // redeem wusd
    _cdRedeemwUSD(alice, aliceBalanceAfterFee);

    uint256 redeemFeeAmount = aliceBalanceAfterFee.mul(wusd.redeemFeeRate()).div(wusd.FEE_COEFFICIENT());
    uint256 aliceBalanceAfterRedeemFee = aliceBalanceAfterFee.sub(redeemFeeAmount);
    uint256 convertToUSDC = aliceBalanceAfterRedeemFee.div(1e12);
    // alice burn wusd minus fee
    assertEq(wusd.balanceOf(alice), 0 ether);
    // feeRecipient get fee in wusd
    assertEq(wusd.balanceOf(feeRecipient), feeAmount + redeemFeeAmount);
    // spct pool balance in wusd
    assertEq(spct.balanceOf(address(wusd)), convertToSPCT - aliceBalanceAfterRedeemFee);

    vm.warp(block.timestamp + 3 days);

    // treasury must transfer usdc to wusd before user redeem cd period ends
    vm.startPrank(treasury);
    usdc.approve(address(wusd), convertToUSDC);
    usdc.transfer(address(wusd), convertToUSDC);
    vm.stopPrank();

    // redeem wusd
    _redeemwUSD(alice);

    // alice get usdc
    assertEq(usdc.balanceOf(alice), convertToUSDC);
  }

  function testwUSDMintRedeemWithSPCTFee() public {
    vm.startPrank(manager);
    spct.addToWhitelist(feeRecipient);
    spct.setMintFeeRate(100000);
    spct.setRedeemFeeRate(100000);
    spct.setFeeRecipient(feeRecipient);
    vm.stopPrank();

    // Mint wusd
    uint256 aliceMinted = 100 ether;
    uint256 aliceMintedInDecimals6 = _convertToDecimals6(aliceMinted);
    _mintwUSD(alice, aliceMintedInDecimals6);

    // check balance wusd
    uint256 convertToSPCT = aliceMintedInDecimals6.mul(1e12);
    uint256 spctFeeAmount = convertToSPCT.mul(spct.mintFeeRate()).div(wusd.FEE_COEFFICIENT());
    uint256 aliceBalanceAfterFee = convertToSPCT.sub(spctFeeAmount);
    // alice get wusd minus fee
    assertEq(wusd.balanceOf(alice), aliceBalanceAfterFee);
    // feeRecipient get fee in wusd
    assertEq(spct.balanceOf(feeRecipient), spctFeeAmount);
    // wusd store spct - fee amount
    assertEq(spct.balanceOf(address(wusd)), aliceBalanceAfterFee);

    vm.warp(block.timestamp + 1 days);

    // redeem wusd
    _cdRedeemwUSD(alice, aliceBalanceAfterFee);

    uint256 spctRedeemFeeAmount = aliceBalanceAfterFee.mul(spct.redeemFeeRate()).div(wusd.FEE_COEFFICIENT());
    uint256 aliceBalanceAfterRedeemFee = aliceBalanceAfterFee.sub(spctRedeemFeeAmount);
    uint256 convertToUSDC = aliceBalanceAfterRedeemFee.div(1e12);
    // alice burn wusd minus fee
    assertEq(wusd.balanceOf(alice), 0 ether);
    // feeRecipient get fee in wusd
    assertEq(spct.balanceOf(feeRecipient), spctFeeAmount + spctRedeemFeeAmount);
    // spct pool balance in wusd
    assertEq(spct.balanceOf(address(wusd)), 0 ether);

    vm.warp(block.timestamp + 3 days);

    // treasury must transfer usdc to wusd before user redeem cd period ends
    vm.startPrank(treasury);
    usdc.approve(address(wusd), convertToUSDC);
    usdc.transfer(address(wusd), convertToUSDC);
    vm.stopPrank();

    // redeem wusd
    _redeemwUSD(alice);
    // alice get usdc
    assertEq(usdc.balanceOf(alice), convertToUSDC);
  }

  function testwUSDMintWithBothFee() public {
    vm.startPrank(manager);
    // wusd
    wusd.setMintFeeRate(1000000);
    wusd.setRedeemFeeRate(1000000);
    wusd.setFeeRecipient(feeRecipient);
    // spct
    spct.addToWhitelist(feeRecipient);
    spct.setMintFeeRate(1000000);
    spct.setRedeemFeeRate(1000000);
    spct.setFeeRecipient(feeRecipient);
    vm.stopPrank();
    
    // Mint wusd
    uint256 aliceMinted = 100 ether;
    uint256 aliceMintedInDecimals6 = _convertToDecimals6(aliceMinted);
    _mintwUSD(alice, aliceMintedInDecimals6);

    // check balance wusd
    uint256 convertToSPCT = aliceMintedInDecimals6.mul(1e12);
    // spct fee
    uint256 spctFeeAmount = convertToSPCT.mul(spct.mintFeeRate()).div(wusd.FEE_COEFFICIENT());
    uint256 spctAmountAfterFee = convertToSPCT.sub(spctFeeAmount);
    // wusd fee
    uint256 feeAmount = spctAmountAfterFee.mul(wusd.mintFeeRate()).div(wusd.FEE_COEFFICIENT());
    uint256 amountAfterFee = spctAmountAfterFee.sub(feeAmount);
    // check wusd balance
    assertEq(wusd.balanceOf(alice), amountAfterFee);
    assertEq(wusd.balanceOf(feeRecipient), feeAmount);
    // check spct balance
    assertEq(spct.balanceOf(feeRecipient), spctFeeAmount);
    assertEq(spct.balanceOf(address(wusd)), spctAmountAfterFee);

    vm.warp(block.timestamp + 1 days);

    // redeem wusd
    _cdRedeemwUSD(alice, amountAfterFee);

    uint256 wusdRedeemFeeAmount = amountAfterFee.mul(wusd.redeemFeeRate()).div(wusd.FEE_COEFFICIENT());
    uint256 amountAfterRedeemFee = amountAfterFee.sub(wusdRedeemFeeAmount);
    uint256 spctRedeemFeeAmount = amountAfterRedeemFee.mul(spct.redeemFeeRate()).div(wusd.FEE_COEFFICIENT());
    uint256 amountAfterRedeemSPCTFee = amountAfterRedeemFee.sub(spctRedeemFeeAmount);
    uint256 convertToUSDC = amountAfterRedeemSPCTFee.div(1e12);
     // alice burn wusd minus fee
    assertEq(wusd.balanceOf(alice), 0 ether);
    // feeRecipient get fee in wusd
    assertEq(wusd.balanceOf(feeRecipient), feeAmount + wusdRedeemFeeAmount);
    // feeRecipient get fee in spct
    assertEq(spct.balanceOf(feeRecipient), spctFeeAmount + spctRedeemFeeAmount);

    vm.warp(block.timestamp + 3 days);

    // treasury must transfer usdc to wusd before user redeem cd period ends
    vm.startPrank(treasury);
    usdc.approve(address(wusd), convertToUSDC);
    usdc.transfer(address(wusd), convertToUSDC);
    vm.stopPrank();

    // redeem wusd
    _redeemwUSD(alice);
    // alice get usdc
    assertEq(usdc.balanceOf(alice), convertToUSDC);
    // spct pool balance in wusd
    uint256 expectedSPCTBalanceInwUSD = spctAmountAfterFee.sub(amountAfterRedeemFee);
    assertEq(spct.balanceOf(address(wusd)), expectedSPCTBalanceInwUSD);
    // usdc balance in spct
    uint256 expectedUSDCBalanceInSPCT = aliceMintedInDecimals6.sub(convertToUSDC);
    assertEq(usdc.balanceOf(treasury), expectedUSDCBalanceInSPCT);
  } 

  function testSpctDepositByFiatAndwUSDDepositBySPCT() public {
    // deposit by fiat
    vm.startPrank(manager);
    spct.addToWhitelist(alice);
    spct.depositByFiat(alice, 100 ether);
    vm.stopPrank();

    assertEq(spct.balanceOf(alice), 100 ether);

    // deposit by spct
    vm.startPrank(alice);
    spct.approve(address(wusd), type(uint256).max);
    wusd.depositBySPCT(100 ether);
    vm.stopPrank();

    assertEq(spct.balanceOf(address(wusd)), 100 ether);
    assertEq(spct.balanceOf(alice), 0 ether);
    assertEq(wusd.balanceOf(alice), 100 ether);

    vm.warp(block.timestamp + 1 days);

    vm.startPrank(alice);
    wusd.redeemBackSPCT(100 ether);
    vm.stopPrank();

    assertEq(spct.balanceOf(address(wusd)), 0 ether);
    assertEq(spct.balanceOf(alice), 100 ether);
    assertEq(wusd.balanceOf(alice), 0 ether);

    vm.startPrank(manager);
    spct.redeemByFiat(alice, 100 ether);
    vm.stopPrank();

    assertEq(spct.balanceOf(alice), 0 ether);
    assertEq(spct.balanceOf(address(wusd)), 0 ether);
  }

  function testStakingSuccess() public {
    // mint wusd
    uint256 mintValue = 100 ether;
    uint256 mintValueInDecimals6 = _convertToDecimals6(mintValue);
    // alice will get full yield
    _mintwUSD(alice, mintValueInDecimals6);
    // bob will get half yield
    _mintwUSD(bobby, mintValueInDecimals6);

    assertEq(wusd.balanceOf(alice), mintValue);
    assertEq(wusd.balanceOf(bobby), mintValue);

    // alice and bobby stake wusd
    _stakewUSD(alice, mintValue);
    _stakewUSD(bobby, mintValue);

    assertEq(wusd.balanceOf(alice), 0);
    assertEq(wusd.balanceOf(bobby), 0);

    assertEq(swusd.balanceOf(alice), mintValue);
    assertEq(swusd.balanceOf(bobby), mintValue);
    
    // check if manager didn't add yield will value change
    vm.warp(block.timestamp + 10 days);
    assertEq(swusd.balanceOf(alice), mintValue);
    assertEq(swusd.balanceOf(bobby), mintValue);

    // unstake following cooldown period
    vm.startPrank(alice);
    swusd.CDAssets(mintValue);
    vm.stopPrank();

    vm.warp(block.timestamp + 1 days);
    vm.startPrank(alice);
    vm.expectRevert("UNSTAKE_FAILED");
    swusd.unstake();
    vm.stopPrank();

    // unstake
    vm.warp(block.timestamp + 3 days);
    vm.startPrank(alice);
    swusd.unstake();
    vm.stopPrank();

    assertEq(swusd.balanceOf(alice), 0);
    assertEq(wusd.balanceOf(alice), mintValue);
  }

  function testStakingSuccessAndYield() public {
    // manager mint wusd for yield
    uint256 managerMintValue = 1000 ether;
    _mintwUSD(manager, _convertToDecimals6(managerMintValue));

    // set yield period
    vm.startPrank(manager);
    uint256 vestingPeriod = 10 days;
    swusd.setNewVestingPeriod(vestingPeriod);
    vm.stopPrank();

    // alice will stake before vesting period
    uint256 aliceMintValue = 100 ether;
    uint256 aliceMintValueInDecimals6 = _convertToDecimals6(aliceMintValue);
    _mintwUSD(alice, aliceMintValueInDecimals6);
    assertEq(wusd.balanceOf(alice), aliceMintValue);
    // bobby will stake 5 days after vesting period
    uint256 bobbyMintValue = 100 ether;
    uint256 bobbyMintValueInDecimals6 = _convertToDecimals6(bobbyMintValue);
    _mintwUSD(bobby, bobbyMintValueInDecimals6);
    assertEq(wusd.balanceOf(bobby), bobbyMintValue);

    // -------- Start Staking --------
    // alice stake wusd
    _stakewUSD(alice, aliceMintValue);
    assertEq(wusd.balanceOf(alice), 0);
    assertEq(swusd.balanceOf(alice), aliceMintValue);

    // manager add yield
    vm.warp(block.timestamp + 1 days);
    vm.startPrank(manager);
    wusd.approve(address(swusd), type(uint256).max);
    uint256 yieldVestingAmount = 100 ether;
    swusd.addYield(yieldVestingAmount);
    assertEq(wusd.balanceOf(address(swusd)), yieldVestingAmount.add(aliceMintValue));
    vm.stopPrank();

    // check alice after 1 day of vesting period end
    vm.warp(block.timestamp + 1 days);
    uint256 totalAssets = aliceMintValue.add(yieldVestingAmount); // 200 ether
    uint256 elapsedTime = 1 days;
    uint256 unvestedAmount = yieldVestingAmount.mul(vestingPeriod - elapsedTime).div(vestingPeriod);
    uint256 vestedAssets = totalAssets.sub(unvestedAmount);

    // Calculate expected assets (wUSD) for Alice's shares
    uint256 expectedAssets = vestedAssets.mul(aliceMintValue).div(aliceMintValue); // Alice has 100% of shares
    assertApproxEqAbs(swusd.convertToAssets(aliceMintValue), expectedAssets, 1); // use this because of rounding issue

    // Calculate expected shares (swUSD) for Alice's assets
    uint256 expectedShares = aliceMintValue.mul(aliceMintValue).div(vestedAssets);
    assertApproxEqAbs(swusd.convertToShares(aliceMintValue), expectedShares, 1);

    // check alice after 4 days of vesting period end
    vm.warp(block.timestamp + 3 days);

    uint256 aliceSharesBefore = swusd.balanceOf(alice);
    uint256 aliceAssetsBefore = swusd.convertToAssets(aliceSharesBefore);

    _stakewUSD(bobby, bobbyMintValue);

    uint256 bobbyShares = swusd.balanceOf(bobby);

    // Recalculate Alice's assets after Bobby's stake
    uint256 aliceAssetsAfter = swusd.convertToAssets(aliceSharesBefore);

    // Assert that Alice's assets have increased due to yield
    assert(aliceAssetsAfter > aliceAssetsBefore);

    // Assert that Bobby's shares are less than his initial stake due to the increased asset-to-share ratio
    assert(bobbyShares < bobbyMintValue);

    // check alice & bobby after 5 days of vesting period end
    vm.warp(block.timestamp + 1 days);

    uint256 totalShares = swusd.totalSupply();
    uint256 totalAssetsAfter5Days = swusd.totalAssets();

    // Recalculate expected assets for Alice and Bobby
    uint256 aliceExpectedAssets = totalAssetsAfter5Days.mul(aliceSharesBefore).div(totalShares);
    uint256 bobbyExpectedAssets = totalAssetsAfter5Days.mul(bobbyShares).div(totalShares);

    assertApproxEqAbs(swusd.convertToAssets(aliceSharesBefore), aliceExpectedAssets, 1e15); // 0.001 wUSD tolerance
    assertApproxEqAbs(swusd.convertToAssets(bobbyShares), bobbyExpectedAssets, 1e15); // 0.001 wUSD tolerance

    // Calculate expected shares for Alice's and Bobby's assets
    uint256 aliceExpectedShares = aliceExpectedAssets.mul(totalShares).div(totalAssetsAfter5Days);
    uint256 bobbyExpectedShares = bobbyExpectedAssets.mul(totalShares).div(totalAssetsAfter5Days);

    assertApproxEqAbs(swusd.convertToShares(aliceExpectedAssets), aliceExpectedShares, 1); // 1 wei tolerance
    assertApproxEqAbs(swusd.convertToShares(bobbyExpectedAssets), bobbyExpectedShares, 1); // 1 wei tolerance

    // vesting period end
    vm.warp(block.timestamp + 5 days);

    // At this point, it's been 10 days since the yield was added
    // The entire yield should be vested now

    // Calculate final assets and shares for Alice and Bobby
    uint256 finalTotalAssets = swusd.totalAssets();
    uint256 finalTotalShares = swusd.totalSupply();

    uint256 aliceFinalShares = swusd.balanceOf(alice);
    uint256 bobbyFinalShares = swusd.balanceOf(bobby);

    uint256 aliceFinalAssets = swusd.convertToAssets(aliceFinalShares);
    uint256 bobbyFinalAssets = swusd.convertToAssets(bobbyFinalShares);

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
    swusd.CDAssets(aliceFullBalance);
    vm.stopPrank();

    // Bobby unstakes
    vm.startPrank(bobby);
    uint256 bobbyFullBalance = bobbyMintValue.add(bobbyYieldEarned);
    swusd.CDAssets(bobbyFullBalance);
    vm.stopPrank();

    // Wait for the cooldown period
    vm.warp(block.timestamp + 3 days);

    // Alice completes unstaking
    vm.startPrank(alice);
    swusd.unstake();
    vm.stopPrank();

    // Bobby completes unstaking
    vm.startPrank(bobby);
    swusd.unstake();
    vm.stopPrank();
    
    // Assert that swUSD balances are now zero
    assertEq(swusd.balanceOf(alice), 0, "Alice's swUSD balance should be zero after unstaking");
    assertEq(swusd.balanceOf(bobby), 0, "Bobby's swUSD balance should be zero after unstaking");

    // Assert that the total supply of swUSD is now zero (or very close to zero due to potential rounding)
    assertApproxEqAbs(swusd.totalSupply(), 0, 1, "Total supply of swUSD should be zero after all unstaking");

    // Assert that the total assets in swUSD contract is now zero (or very close to zero)
    assertApproxEqAbs(swusd.totalAssets(), 0, 1e15, "Total assets in swUSD should be zero after all unstaking");
  }

  // for easier read the test
  function _convertToDecimals6(uint256 _amount) internal pure returns (uint256) {
    return _amount / 10**12;
  }

  function _mintwUSD(address _who, uint256 _amount) internal {
    vm.startPrank(_who);
    usdc.approve(address(wusd), type(uint256).max);
    wusd.deposit(_who,_amount);
    vm.stopPrank();
  }

  function _cdRedeemwUSD(address _who, uint256 _amount) internal {
    vm.startPrank(_who);
    wusd.cdRedeem(_amount);
    vm.stopPrank();
  }

  function _redeemwUSD(address _who) internal {
    vm.startPrank(_who);
    wusd.redeem();
    vm.stopPrank();
  }

  function _stakewUSD(address _who, uint256 _amount) internal {
    vm.startPrank(_who);
    wusd.approve(address(swusd), type(uint256).max);
    swusd.deposit(_amount, _who);
    vm.stopPrank();
  }

}
