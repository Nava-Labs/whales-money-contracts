// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ISPCTPriceOracle {
    function SPCT_USD_ORACLE_ADDRESS() external view returns (address);
    function getPrice() external view returns (uint256);
    function heartbeat() external view returns (uint256);
}