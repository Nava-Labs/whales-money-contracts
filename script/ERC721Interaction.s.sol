// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {SimpleERC721} from "../src/mock/SimpleERC721.sol";

contract DeploySimpleERC721 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleERC721 erc721 = new SimpleERC721(
            "Ethereum",
            "ETH"
        );

        console.log(
            "SimpleERC721 contract deployed with address: ",
            address(erc721)
        );

        vm.stopBroadcast();
    }
}

