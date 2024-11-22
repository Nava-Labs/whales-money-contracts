// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {MockStakingDirect,MockStakingWithRouter,MockStakingHop1,MockStakingHop2,MockStakingHop3} from "../src/mock/MockStaking.sol";

contract DeployMockStaking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address usdb = 0xE70b4B2BD4026D8E286F52cf45Ab71F04CD50EFA;

        MockStakingDirect _mock1 = new MockStakingDirect(
            usdb
        );

        address[] memory target = new address[](3);
        target[0] = 0xD76e2A1c4a1EB7328c742479F7D92847C493c986;
        target[1] = 0x7f1c3121E8578E406a5c245308AA1a141230435F;
        target[2] = 0x000000000000000000000000000000000000dEaD;

        MockStakingWithRouter _mock0 = new MockStakingWithRouter(
            usdb,
            target
        );

        MockStakingHop3 _hop3 = new MockStakingHop3(
            usdb
        );

        MockStakingHop2 _hop2 = new MockStakingHop2(
            usdb,
            address(_hop3)
        );

        MockStakingHop1 _hop1 = new MockStakingHop1(
            usdb,
            address(_hop2)
        );

        vm.stopBroadcast();
    }
}
