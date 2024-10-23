// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IBridgeToken {
    function decimals() external view returns (uint8);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}