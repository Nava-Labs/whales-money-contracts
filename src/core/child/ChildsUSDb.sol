// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/token/ERC677/OpStackBurnMintERC677.sol";

/**
 * @title Child version sUSDb for Bondlink protocol. (for bridging)
 */
contract ChildsUSDb is OpStackBurnMintERC677 {
    using SafeERC20 for IERC20;

    constructor(
        address l1Token,
        address l2Bridge
    ) OpStackBurnMintERC677("Staked USDb", "sUSDb", 18, 0, l1Token, l2Bridge) {}

    /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param token ERC20 token contract address.
     * @param to recipient address.
     * @param amount amount to withdraw.
     */
    function rescueERC20(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }
}
