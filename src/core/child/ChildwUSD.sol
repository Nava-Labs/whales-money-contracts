// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

/**
 * @title Child version wUSD for WhalesMoney protocol. (for bridging)
 */
contract ChildwUSD is OFT, ERC20Permit, Pausable {
    using SafeERC20 for IERC20;

    // Make owner transfer 2 step.
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    constructor(
        address _endpoint,
        address _owner // token owner used as a delegate in LayerZero Endpoint
    ) OFT("wUSD", "wUSD", _endpoint, _owner) ERC20Permit("wUSD") Ownable(_owner) {}

    // @dev Sets an implicit cap on the amount of tokens, over uint64.max() will need some sort of outbound cap / totalSupply cap
    // Lowest common decimal denominator between chains.
    // Defaults to 6 decimal places to provide up to 18,446,744,073,709.551615 units (max uint64).
    // For tokens exceeding this totalSupply(), they will need to override the sharedDecimals function with something smaller.
    // ie. 4 sharedDecimals would be 1,844,674,407,370,955.1615
    function sharedDecimals() public pure override returns (uint8) {
        return 8;
    }

    /**
     * @notice Pause the contract. Revert if already paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract. Revert if already unpaused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // override to allow pausing
    function _debit(uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        override
        whenNotPaused
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        return super._debit(_amountLD, _minAmountLD, _dstEid);
    }

    // override to allow pausing
    function _credit(address _to, uint256 _amountLD, uint32 _srcEid)
        internal
        override
        whenNotPaused
        returns (uint256 amountReceivedLD)
    {
        return super._credit(_to, _amountLD, _srcEid);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Ownable2Step                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }

    /* --------------------------- End of Ownable2Step -------------------------- */

    /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param token ERC20 token contract address.
     * @param to recipient address.
     * @param amount amount to withdraw.
     */
    function rescueERC20(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }
}
