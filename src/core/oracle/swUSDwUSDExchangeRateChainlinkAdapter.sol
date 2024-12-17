// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IswUSD } from "../../interfaces/IswUSD.sol";
import { MinimalAggregatorV3Interface } from "../../interfaces/MinimalAggregatorV3Interface.sol";

/// @title swUSDwUSDExchangeRateChainlinkAdapter
/// @author Morpho Labs (modified from WstEthStEthExchangeRateChainlinkAdapter)
/// @notice swUSD/wUSD exchange rate price feed.
/// @dev This contract should only be deployed on Ethereum and used as a price feed for Morpho oracles.
contract swUSDwUSDExchangeRateChainlinkAdapter is MinimalAggregatorV3Interface {
    /// @inheritdoc MinimalAggregatorV3Interface
    // @dev The calculated price has 18 decimals precision, whatever the value of `decimals`.
    uint8 public constant decimals = 18;

    /// @notice The description of the price feed.
    string public constant description = "swUSD/wUSD exchange rate";

    /// @notice The address of swUSD on Ethereum.
    IswUSD public immutable swUSD;

    constructor(address _swUSD) {
        swUSD = IswUSD(_swUSD);
    }

    /// @dev Returns zero for roundId, startedAt, updatedAt and answeredInRound.
    /// @dev Silently overflows if `convertToAssets`'s return value is greater than `type(int256).max`.
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        // It is assumed that `getPooledEthByShares` returns a price with 18 decimals precision.
        return (0, int256(swUSD.convertToAssets(1 ether)), 0, 0, 0);
    }
}
