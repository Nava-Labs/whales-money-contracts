// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Used to put cooldown USDb from sUSDb contract.
 */
contract USDbFlat {
    address public immutable susdb;
    IERC20 public immutable usdb;

    constructor(address _susdb, IERC20 _usdb) {
        susdb = _susdb;
        usdb = _usdb;
    }

    modifier onlysUSDb() {
        require(msg.sender == susdb, "CAN_ONLY_CALLED_BY_SUSDB");
        _;
    }

    function withdraw(address _to, uint256 _amount) external onlysUSDb {
        usdb.transfer(_to, _amount);
    }
}
