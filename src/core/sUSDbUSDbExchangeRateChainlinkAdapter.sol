// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IsUSDb } from "../interfaces/IsUSDb.sol";
import { MinimalAggregatorV3Interface } from "../interfaces/MinimalAggregatorV3Interface.sol";

/// @title sUSDbUSDbExchangeRateChainlinkAdapter
/// @author Morpho Labs (modified from WstEthStEthExchangeRateChainlinkAdapter)
/// @notice sUSDb/USDb exchange rate price feed.
/// @dev This contract should only be deployed on Ethereum and used as a price feed for Morpho oracles.
contract sUSDbUSDbExchangeRateChainlinkAdapter is MinimalAggregatorV3Interface {
    /// @inheritdoc MinimalAggregatorV3Interface
    // @dev The calculated price has 18 decimals precision, whatever the value of `decimals`.
    uint8 public constant decimals = 18;

    /// @notice The description of the price feed.
    string public constant description = "sUSDb/USDb exchange rate";

    /// @notice The address of sUSDb on Ethereum.
    IsUSDb public constant sUSDb = IsUSDb(0x547213367cfB08ab418E7b54d7883b2C2AA27Fd7);

    /// @dev Returns zero for roundId, startedAt, updatedAt and answeredInRound.
    /// @dev Silently overflows if `convertToAssets`'s return value is greater than `type(int256).max`.
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        // It is assumed that `getPooledEthByShares` returns a price with 18 decimals precision.
        return (0, int256(sUSDb.convertToAssets(1 ether)), 0, 0, 0);
    }
}
