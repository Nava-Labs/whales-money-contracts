// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockStaking1 {
    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function stake(uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address _to, uint256 _amount) external {
        IERC20(token).transfer(_to, _amount);
    }
}
