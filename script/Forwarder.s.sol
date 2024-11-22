// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Forwarder} from "../src/core/Forwarder.sol";

contract ForwarderScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address _owner = 0x62507d7B6d8428DA9F8D337B5aE59c115340D049;
        address _usdc = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        address _usdb = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        Forwarder _forwarder = new Forwarder(_owner,_usdc, _usdb);

        vm.stopBroadcast();
        
    }

    function addToWhitelist(address payable _forwarder, address _user) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Forwarder(_forwarder).addToWhitelist(_user);

        vm.stopBroadcast();
    }

    function removeFromWhitelist(address payable _forwarder, address _user) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Forwarder(_forwarder).removeFromWhitelist(_user);

        vm.stopBroadcast();
    }

    function dropUSDCandContinue(
        address payable _forwarder, 
        address payable _to, 
        bool _isNative,
        address _token,
        uint256 _tokenAmount,
        bytes calldata _data,
        uint256 _ethValueInWei
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Forwarder(_forwarder).dropUSDCandContinue{value: _ethValueInWei}(
            _to, 
            _isNative,
            _token,
            _tokenAmount,
            _data
        );

        vm.stopBroadcast();
    }

    function withdrawETH(address payable _forwarder, address _receiver) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Forwarder(_forwarder).withdrawETH(_receiver);

        vm.stopBroadcast();
    }

    function withdrawERC20(address payable _forwarder, address _token, address _receiver) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Forwarder(_forwarder).withdrawERC20(_token, _receiver);

        vm.stopBroadcast();
    }
}
