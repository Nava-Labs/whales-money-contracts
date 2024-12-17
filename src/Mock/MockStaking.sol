// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockStakingDirect { IERC20 public token;

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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IwUsd {
    function deposit(address receiver, uint256 _amount) external;
}

contract MockStakingWithRouter {
    IERC20 public wusd;

    address[] public target;

    constructor(address _wusd, address[] memory _target) {
        wusd = IERC20(_wusd);
        target = _target;
    }

    function routeWUSDtoTarget(uint256 amount) external {
        IERC20(wusd).transferFrom(msg.sender, address(this), amount);

        for(uint i; i < target.length; i++) {
            IERC20(wusd).transfer(target[i], amount / target.length);
        }
    }

    function withdraw(address _to, uint256 _amount) external {
        IERC20(wusd).transfer(_to, _amount);
    }
}

interface IHopper {
    function hop(uint256 amount) external;
}

contract MockStakingHop1 {
    IERC20 public wusd;

    address public hop2;

    constructor(address _wusd, address _hop2) {
        wusd = IERC20(_wusd);
        hop2 = _hop2;

        IERC20(wusd).approve(hop2, type(uint256).max);        
    }

    function routeWUSDtoHop2(uint256 amount) external {
        IERC20(wusd).transferFrom(msg.sender, address(this), amount);
        IHopper(hop2).hop(amount);
    }
}

contract MockStakingHop2 is IHopper {
    IERC20 public wusd;

    address public hop3;

    constructor(address _wusd, address _hop3) {
        wusd = IERC20(_wusd);
        hop3 = _hop3;

        IERC20(wusd).approve(hop3, type(uint256).max);        
    }

    function hop(uint256 amount) external {
        IERC20(wusd).transferFrom(msg.sender, address(this), amount);
        IHopper(hop3).hop(amount);
    }
}

contract MockStakingHop3 { 
    IERC20 public wusd;

    constructor(address _wusd) {
        wusd = IERC20(_wusd);
    }

    function hop(uint256 amount) external {
        IERC20(wusd).transferFrom(msg.sender, address(this), amount);
    }

    function claim(uint256 amount) external {
        IERC20(wusd).transfer(msg.sender, amount);
    }
}
