# Whales Money - Anzen Finance Fork

## Overview

Whales Money is a fork of [Anzen Finance](https://docs.anzen.finance/) with significant modifications to core functionality

---

## Key Modifications

### USDC to WUSD Conversion

- **Direct Treasury Deposit**: USDC is sent directly to the treasury address (multisig) instead of being locked in WUSD contracts.

### WUSD to USDC Redemption

- **Cooldown Mechanism**: Redeeming WUSD back to USDC involves a cooldown period, similar to the process of converting sWUSD to WUSD.
- **Manual Approval**: The admin monitors the redemption list and transfers USDC to the WUSD contract, enabling users to claim their USDC.
- **KYC Requirement**: Signatures are required for "CDRedeem" and "Redeem" processes, ensuring the user has completed KYC verification.

---

## Oracle Implementation

- **Current Status**: `SPCTPriceOracle` is used as a placeholder for testing purposes.
- **Mainnet Plans**: On mainnet, we will implement an architecture similar to Anzen's unverified oracle (`src/core/oracle/AnzenOracle`).
  - Anzen's implementation appears to hardcode the USDC value as `1` within the `getPrice()` function.
  - Reference:
    - [Contract 1](https://etherscan.io/address/0xA469B7Ee9ee773642b3e93E842e5D9b5BaA10067#readContract)
    - [Contract 2](https://etherscan.io/address/0x900FFF3Bbf47dED50Fd4940D055E1324F38B0d4f)
  - My plan is to deploy the same bytecode.

We welcome feedback on this approach.

---

## Omnichain Architecture

### WUSD Implementation

- **Mainnet (Ethereum)**:
  - `WUSD.sol` - Primary token contract.
- **Other Chains**:
  - `ChildwUSD.sol` - Implementation for child chains.

### sWUSD Implementation

_Note: An adapter is necessary as staking WUSD to obtain sWUSD can only occur on Ethereum mainnet._

- **Mainnet (Ethereum)**:
  - `sWUSD.sol` - Main staked WUSD contract.
  - `swUSDOFTAdapter.sol` - LayerZero adapter for cross-chain operations.
- **Other Chains**:
  - `ChildswUSD.sol` - Child chain staked token contract.
  - `Whales MoneyLayerZeroAdapter.sol` - Adapter for cross-chain communication.

---

## Multi-Token Support (`Forwarder.sol`)

- **Core Features**:
  - Multi-token swap functionality using low-level calls.
  - Direct WUSD deposit following USDC conversion.
- **DEX Integration**:
  - Primary: Paraswap.
  - Supports various DEX protocols via a generic swap interface.
