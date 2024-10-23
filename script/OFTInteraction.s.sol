// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {EnforcedOptionParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import {IOFT, SendParam, OFTFeeDetail, OFTReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

contract OFTInteraction is Script {
    uint32 public constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 public constant ULN_CONFIG_TYPE = 2;
    uint32 public constant RECEIVE_CONFIG_TYPE = 2;

    // 1. Enforcing minimum gas limit via options
    function setEnforcedOptions(address _oft, uint32 _eid) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        uint16 SEND = 1;
        bytes memory optionType3 = OptionsBuilder.newOptions();
        bytes memory options = OptionsBuilder.addExecutorLzReceiveOption(optionType3, 60000, 0); // 60000 for OFT transfer

        EnforcedOptionParam[] memory _enforcedOptions = new EnforcedOptionParam[](1);
        _enforcedOptions[0] = EnforcedOptionParam({eid: _eid, msgType: SEND, options: options}); // gas limit, msg.value

        vm.startBroadcast(deployerPrivateKey);

        OFT(_oft).setEnforcedOptions(_enforcedOptions);

        vm.stopBroadcast();
    }

    // 2. Set Send Library and Receive Library (explicitly setting the _sendLib and _reciveLib)
    // So, we wont affected by any futher L0 updates
    // SEE: https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#setting-send-and-receive-libraries
    function setLibrary(address _oft, uint32 _eid, address _sendLib, address _receiveLib) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        OFT myOFT = OFT(_oft);
        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(myOFT.endpoint()));
        
        vm.startBroadcast(deployerPrivateKey);

        // Set the send library
        endpoint.setSendLibrary(_oft, _eid, _sendLib);
        console.log("Send library set successfully.");

        // Set the receive library
        endpoint.setReceiveLibrary(_oft, _eid, _receiveLib, 0);
        console.log("Receive library set successfully.");

        vm.stopBroadcast();
    }


    // 3. Set Send Config, defining Security Stack and Executor Configuration
    // SEE: https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#setting-send-config
    function setSendConfig(
        address _oft, 
        uint32 _eid, 
        address sendLibraryAddress
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        OFT oft = OFT(_oft);
        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(oft.endpoint()));

        SetConfigParam[] memory setConfigParams = new SetConfigParam[](2);

        ExecutorConfig memory executorConfig = ExecutorConfig({
            maxMessageSize: 100000,
            // https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts (LZ Executor)
            executor: 0x8A3D588D9f6AC041476b094f97FF94ec30169d3D // Base sepolia
        });

        // SEE: https://docs.layerzero.network/v2/developers/evm/technical-reference/dvn-addresses
        // NOTES: DVNs MUST MATCH between SEND CONFIG AND RECEIVE CONFIG
        address[] memory chosenDVNs = new address[](2);
        chosenDVNs[0] = 0xe1a12515F9AB2764b887bF60B923Ca494EBbB2d6; // L0 DVN should be number one
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
            eid: _eid,
            configType: EXECUTOR_CONFIG_TYPE,
            config: abi.encode(executorConfig)
        });

        setConfigParams[1] = SetConfigParam({
            eid: _eid,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        vm.startBroadcast(deployerPrivateKey);

        endpoint.setConfig(address(oft), sendLibraryAddress, setConfigParams);

        vm.stopBroadcast();
    }


    // 4. Set Receive Config, defining Security Stack and Executor Configuration
    // SEE: https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#setting-receive-config
    function setReceiveConfig(address _oft, uint32 _eid, address receiveLibraryAddress) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        OFT oft = OFT(_oft);
        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(oft.endpoint()));

        // SEE: https://docs.layerzero.network/v2/developers/evm/technical-reference/dvn-addresses
        // NOTES: DVNs MUST MATCH between SEND CONFIG AND RECEIVE CONFIG
        address[] memory chosenDVNs = new address[](2);
        chosenDVNs[0] = 0x0eE552262f7B562eFcED6DD4A7e2878AB897d405;
        chosenDVNs[1] = 0x16b711e3284E7C1d3b7EEd25871584AD8D946cAC;

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
            eid: _eid,
            configType: RECEIVE_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        vm.startBroadcast(deployerPrivateKey);

        endpoint.setConfig(address(oft), receiveLibraryAddress, setConfigParams);

        vm.stopBroadcast();
    }

    // FOR RESETTING SEND CONFIG
    function resetSendConfig(
        address _oft, 
        uint32 _eid,
        address sendLibraryAddress
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        OFT oft = OFT(_oft);
        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(oft.endpoint()));

        SetConfigParam[] memory setConfigParams = new SetConfigParam[](2);

        ExecutorConfig memory executorConfig = ExecutorConfig({
            maxMessageSize: 0,
            executor: 0x0000000000000000000000000000000000000000
        });

        address[] memory chosenDVNs = new address[](0);
        
        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 0,
            requiredDVNCount: 0,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: chosenDVNs,
            optionalDVNs: new address[](0)
        });
        
        setConfigParams[0] = SetConfigParam({
            eid: _eid,
            configType: EXECUTOR_CONFIG_TYPE,
            config: abi.encode(executorConfig)
        });

        setConfigParams[1] = SetConfigParam({
            eid: _eid,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        vm.startBroadcast(deployerPrivateKey);

        endpoint.setConfig(address(oft), sendLibraryAddress, setConfigParams);

        vm.stopBroadcast();
    }

    // FOR RESETTING RECEIVE CONFIG
    function resetReceiveConfig(address _oft, uint32 _eid, address receiveLibraryAddress) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        OFT oft = OFT(_oft);
        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(oft.endpoint()));

        address[] memory chosenDVNs = new address[](0);
    
        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 0,
            requiredDVNCount: 0,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: chosenDVNs,
            optionalDVNs: new address[](0)
        });

        SetConfigParam[] memory setConfigParams = new SetConfigParam[](1);
        setConfigParams[0] = SetConfigParam({
            eid: _eid,
            configType: RECEIVE_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        vm.startBroadcast(deployerPrivateKey);

        endpoint.setConfig(address(oft), receiveLibraryAddress, setConfigParams);

        vm.stopBroadcast();
    }

    function sendL0(address _oft, uint32 _eid, address _recipientAddress) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        uint256 tokensToSend = 1 ether;
        bytes32 recipientAddress = addressToBytes32(_recipientAddress);
        console2.logBytes32(recipientAddress);

        uint256 amountLD = tokensToSend;
        uint256 minAmountLD = tokensToSend;

        // IF GAS LIMIT NOT ENFORCED, we need to pass `options` in `SendParam` for gas limit
        // IF ENFORCED, we can just passing empty bytes and will use the enforced gas limit
        // IF ENFORCED and we pass `options`, it will `send` with enforcedGasLimit + optionsGasLimit
        bytes memory optionsType3 = OptionsBuilder.newOptions();
        bytes memory options = OptionsBuilder.addExecutorLzReceiveOption(optionsType3, 20000, 0);
        SendParam memory sendParam = SendParam(
            _eid, 
            recipientAddress, 
            amountLD, 
            minAmountLD, 
            // options,
            "",
            "", 
            ""
        );

        MessagingFee memory fee = IOFT(_oft).quoteSend(sendParam, false);
        console2.log(fee.nativeFee);
        console2.log(fee.lzTokenFee);
        
        vm.startBroadcast(deployerPrivateKey);
        IOFT(_oft).send{value: fee.nativeFee}(sendParam, fee, payable(address(this)));
        vm.stopBroadcast();
    }    

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
