// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title SPCT Price Oracle
 */
contract SPCTPriceOracle {

    uint256 private etherPrice = 1 ether;

    function getPrice() external view returns (uint256){
        return etherPrice;
    }

    function setPrice(uint256 newEtherPrice) external {
        etherPrice = newEtherPrice;
    }
    
}