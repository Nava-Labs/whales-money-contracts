// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUsdb {
    function deposit(address receiver, uint256 _amount) external;
}

contract MockStaking2 {
    IERC20 public usdb;

    address public target;

    constructor(address _usdb, address _target) {
        usdb = IERC20(_usdb);
        target = _target;

        IERC20(usdb).approve(target, type(uint256).max);
    }

    function routeUSDBtoTarget(uint256 amount) external {
        IERC20(usdb).transferFrom(msg.sender, address(this), amount);
        IERC20(usdb).transfer(target, amount);
    }

    function withdraw(address _to, uint256 _amount) external {
        IERC20(usdb).transfer(_to, _amount);
    }
}
