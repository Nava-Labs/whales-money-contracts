// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console2 } from "forge-std/console2.sol";
import { USDb } from "../src/v1/USDb.sol";
import { SUSDb } from "../src/v1/sUSDb.sol";
import { USDbFlat } from "../src/v1/USDbFlat.sol";
import { SPCTPool } from "../src/v1/SPCTPool.sol";
import { SPCTPriceOracle } from "../src/v1/SPCTPriceOracle.sol";
import "../interfaces/ISPCTPool.sol";
import "../interfaces/ISPCTPriceOracle.sol";

// LayerZero imports
import { ExecutorConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { SetConfigParam } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { UlnConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

contract DeployBondlinkTestnet is Script {
    function launch() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = 0x00338632793C9566c5938bE85219103C1BC4fDE2;
        address feeRecipient = 0x68E76Ec846501527d08B27BC9259b70f5E590AF6;
        address treasury = 0x904275b0bB34dc3d48A05ae65DF0Bdeb825E751f;
        address endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        IERC20 usdc = IERC20(0x0fbbE1770F92eD1ef5B951d575cE81B6F80bBeb2);
        uint24 cdPeriod = 300;
       
        vm.startBroadcast(deployerPrivateKey);
        // Oracle
        SPCTPriceOracle _oracle = new SPCTPriceOracle();
        // SPCTPool
        SPCTPool _spctPool = new SPCTPool(admin);
        _spctPool.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _spctPool.setFeeRecipient(feeRecipient);
        // USDb
        USDb _usdb = new USDb(admin, endpoint, usdc, ISPCTPool(address(_spctPool)), ISPCTPriceOracle(address(_oracle)), cdPeriod);
        _usdb.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _usdb.setFeeRecipient(feeRecipient);
        _usdb.setTreasury(treasury);
        // sUSDb
        SUSDb _susdb = new SUSDb(admin, IERC20(address(_usdb)), cdPeriod);
        _susdb.grantRole(keccak256("POOL_MANAGER_ROLE"), admin);
        _susdb.grantRole(keccak256("YIELD_MANAGER_ROLE"), admin);
        // Add to whitelist
        _spctPool.addToWhitelist(address(_usdb));
        _spctPool.addToWhitelist(feeRecipient);
        _spctPool.setUsdbAddress(address(_usdb));

        vm.stopBroadcast();

        console2.log("contract deployed on with address: ", address(_oracle));
        console2.log("contract deployed on with address: ", address(_spctPool));
        console2.log("contract deployed on with address: ", address(_usdb));
        console2.log("contract deployed on with address: ", address(_susdb));
    }

    function setLibrary(address _endpoint, address _oapp, uint32 _eid, address _sendLib, address _receiveLib) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // Initialize the endpoint contract
        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(_endpoint);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Set the send library
        endpoint.setSendLibrary(_oapp, _eid, _sendLib);
        console.log("Send library set successfully.");

        // Set the receive library
        endpoint.setReceiveLibrary(_oapp, _eid, _receiveLib, 0);
        console.log("Receive library set successfully.");

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }

    uint32 public constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 public constant ULN_CONFIG_TYPE = 2;

    function setSendConfig(address contractAddress, uint32 remoteEid, address sendLibraryAddress, UlnConfig calldata ulnConfig, ExecutorConfig calldata executorConfig) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        OFT myOFT = OFT(contractAddress);

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(myOFT.endpoint()));

        SetConfigParam[] memory setConfigParams = new SetConfigParam[](2);

        setConfigParams[0] = SetConfigParam({
            eid: remoteEid,
            configType: EXECUTOR_CONFIG_TYPE,
            config: abi.encode(executorConfig)
        });

        setConfigParams[1] = SetConfigParam({
            eid: remoteEid,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        vm.startBroadcast(deployerPrivateKey);

        endpoint.setConfig(address(myOFT), sendLibraryAddress, setConfigParams);

        vm.stopBroadcast();
    }


    uint32 public constant RECEIVE_CONFIG_TYPE = 2;

    function setReceiveConfig(address contractAddress, uint32 remoteEid, address receiveLibraryAddress, UlnConfig calldata ulnConfig) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        OFT myOFT = OFT(contractAddress);

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(myOFT.endpoint()));

        SetConfigParam[] memory setConfigParams = new SetConfigParam[](1);
        setConfigParams[0] = SetConfigParam({
            eid: remoteEid,
            configType: RECEIVE_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        vm.startBroadcast(deployerPrivateKey);

        endpoint.setConfig(address(myOFT), receiveLibraryAddress, setConfigParams);

        vm.stopBroadcast();
    }
    
}
