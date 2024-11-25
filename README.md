# Bondlink - Anzen Finance Fork

## Overview
Bondlink is a fork of [Anzen Finance](https://docs.anzen.finance/) with significant modifications to core functionality

---

## Key Modifications

### USDC to USDB Conversion
- **Direct Treasury Deposit**: USDC is sent directly to the treasury address (multisig) instead of being locked in USDB contracts.

### USDB to USDC Redemption
- **Cooldown Mechanism**: Redeeming USDB back to USDC involves a cooldown period, similar to the process of converting sUSDB to USDB.
- **Manual Approval**: The admin monitors the redemption list and transfers USDC to the USDB contract, enabling users to claim their USDC.
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

### USDB Implementation
- **Mainnet (Ethereum)**: 
  - `USDB.sol` - Primary token contract.
- **Other Chains**: 
  - `ChildUSDb.sol` - Implementation for child chains.

### sUSDB Implementation
*Note: An adapter is necessary as staking USDB to obtain sUSDB can only occur on Ethereum mainnet.*
- **Mainnet (Ethereum)**:
  - `sUSDB.sol` - Main staked USDB contract.
  - `sUSDbOFTAdapter.sol` - LayerZero adapter for cross-chain operations.
- **Other Chains**:
  - `ChildsUSDb.sol` - Child chain staked token contract.
  - `BondlinkLayerZeroAdapter.sol` - Adapter for cross-chain communication.

---

## Multi-Token Support (`Forwarder.sol`)
- **Core Features**:
  - Multi-token swap functionality using low-level calls.
  - Direct USDB deposit following USDC conversion.
- **DEX Integration**:
  - Primary: Paraswap.
  - Supports various DEX protocols via a generic swap interface.
