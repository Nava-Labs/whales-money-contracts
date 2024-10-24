// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error NotWhitelisted();
error FailedDropUSDC(bytes);
error ZeroUSDCDropped();
error FailedWithdrawETH();
error FailedWithdrawERC20();

contract Forwarder is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable USDC;

    mapping(address => bool) public whitelisted;

    modifier onlyWhitelisted(address _to) {
        if(!whitelisted[_to]) revert NotWhitelisted();
        _;
    }

    constructor(address _owner, address _usdc) Ownable(_owner) {
        USDC = IERC20(_usdc);
    }

    function dropUSDCandContinue(
        address payable _to, 
        bool _isNative,
        address _token,
        uint256 _tokenAmount,
        bytes calldata _data
    ) external payable onlyWhitelisted(_to) {
        uint256 usdcBalanceBeforeCall = USDC.balanceOf(address(this));

        if (!_isNative) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _tokenAmount);
            _approve(_token, _to, _tokenAmount);    
        }

        (bool success, bytes memory result) = _to.call{value: msg.value, gas: 500000}(_data);
        if(!success) revert FailedDropUSDC(result);

        uint256 usdcBalanceAfterCall = USDC.balanceOf(address(this));
        if(usdcBalanceAfterCall <= usdcBalanceBeforeCall) revert ZeroUSDCDropped(); 


        // TODO: DEPOSIT USDb
    }

    function addToWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = false;
    }

    function withdrawETH(address _receiver) external onlyOwner {
        (bool success, ) = payable(_receiver).call{value: address(this).balance}("");
        if (!success) revert FailedWithdrawETH();        
    }

    function withdrawERC20(address _token, address _receiver) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_receiver, balance);
    }

    function _approve(address _token, address _spender, uint256 _amount) internal {
        IERC20 token = IERC20(_token);
        token.approve(_spender, _amount);
    }
 
    receive() external payable {}
}
