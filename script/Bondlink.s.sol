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
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {IOFT, SendParam, OFTFeeDetail, OFTReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import { ExecutorConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
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

    function sendL0(address USDB, uint32 dstEid, address _recipientAddress) external {
        uint256 tokensToSend = 1 ether;
        bytes32 recipientAddress = addressToBytes32(_recipientAddress);
        console2.logBytes32(recipientAddress);

        uint256 amountLD = tokensToSend;
        uint256 minAmountLD = tokensToSend;

        bytes memory options = OptionsBuilder.newOptions();
        bytes memory options2 = OptionsBuilder.addExecutorLzReceiveOption(options, 60000, 0);

        SendParam memory sendParam = SendParam(
            dstEid, 
            recipientAddress, 
            amountLD, 
            minAmountLD, 
            options2,
            "", 
            ""
        );

        MessagingFee memory fee = IOFT(USDB).quoteSend(sendParam, false);
        console2.log(fee.nativeFee);
        console2.log(fee.lzTokenFee);
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        IOFT(USDB).send{value: fee.nativeFee}(sendParam, fee, payable(address(this)));
        vm.stopBroadcast();
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
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

    function setSendConfig(
        address contractAddress, 
        uint32 remoteEid, 
        address sendLibraryAddress
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        OFT myOFT = OFT(contractAddress);

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(myOFT.endpoint()));

        SetConfigParam[] memory setConfigParams = new SetConfigParam[](2);

        ExecutorConfig memory executorConfig = ExecutorConfig({
            maxMessageSize: 100000,
            executor: 0x8A3D588D9f6AC041476b094f97FF94ec30169d3D
        });

        address[] memory chosenDVNs = new address[](2);
        chosenDVNs[0] = 0xe1a12515F9AB2764b887bF60B923Ca494EBbB2d6;
        chosenDVNs[1] = 0xfa1a1804eFFeC9000F75CD15d16d18B05738d467;

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 5,
            requiredDVNCount: 2,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: chosenDVNs,
            optionalDVNs: new address[](0)
        });
        
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

    function setReceiveConfig(address contractAddress, uint32 remoteEid, address receiveLibraryAddress) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        OFT myOFT = OFT(contractAddress);

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(myOFT.endpoint()));

        address[] memory chosenDVNs = new address[](2);
        chosenDVNs[0] = 0x53f488E93b4f1b60E8E83aa374dBe1780A1EE8a8;
        chosenDVNs[1] = 0x7c84fEb58183d3865E4e01d1b6C22bA2d227Dc23;

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 5,
            requiredDVNCount: 2,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: chosenDVNs,
            optionalDVNs: new address[](0)
        });

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
