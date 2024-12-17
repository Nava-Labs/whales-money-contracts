// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Used to put cooldown wUSD from swUSD contract.
 */
contract wUSDFlat {
    address public immutable swusd;
    IERC20 public immutable wusd;

    constructor(address _swusd, IERC20 _wusd) {
        swusd = _swusd;
        wusd = _wusd;
    }

    modifier onlySWUSD() {
        require(msg.sender == swusd, "CAN_ONLY_CALLED_BY_SWUSD");
        _;
    }

    function withdraw(address _to, uint256 _amount) external onlySWUSD {
        wusd.transfer(_to, _amount);
    }
}
