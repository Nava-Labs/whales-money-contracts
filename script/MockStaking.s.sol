// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {MockStaking2} from "../src/mock/Staking2.sol";

contract DeployMockStaking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MockStaking2 _mock = new MockStaking2(
            0x42fa6d207347a6c8472a5904E86310Bca48c85ac,
            0xD76e2A1c4a1EB7328c742479F7D92847C493c986
        );

        console.log(
            "MockStaking2 contract deployed with address: ",
            address(_mock)
        );

        vm.stopBroadcast();
    }
}
