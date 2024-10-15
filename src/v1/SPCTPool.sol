// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import "../utils/SafeMath.sol";

/**
 * @title Whitelist Private Credit ERC20-like token for Bondlink protocol.
 */
contract SPCTPool is ERC20Permit, AccessControl, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant POOL_MANAGER_ROLE = keccak256("POOL_MANAGER_ROLE");

    // Used to calculate total executed shares.
    uint256 public executedUSD;
    // Used to calculate total pooled USD.
    uint256 public totalPooledUSD;
    // Used to calculate the reserve USD in pool.
    uint256 public reserveUSD;

    // Fee Zone
    uint256 public constant FEE_COEFFICIENT = 1e8;
    // Fee should be less than 1%.
    uint256 public constant maxMintFeeRate = FEE_COEFFICIENT / 100;
    uint256 public constant maxRedeemFeeRate = FEE_COEFFICIENT / 100;
    uint256 public mintFeeRate;
    uint256 public redeemFeeRate;
    // Protocol feeRecipient should be a mulsig wallet.
    address public feeRecipient;

    // Used to mint SPCT.
    IERC20 public immutable usdc;

    /**
     * @dev SPCT only available for KYC Users.
     */
    mapping(address => bool) private _permission;

    event Deposit(address indexed user, uint256 indexed amount);
    event Redeem(address indexed user, uint256 indexed amount);
    event Execute(uint256 indexed amount);
    event Repay(uint256 indexed amount);

    event MintFeeRateChanged(uint256 indexed newFeeRate);
    event RedeemFeeRateChanged(uint256 indexed newFeeRate);
    event FeeRecipientChanged(address newFeeRecipient);

    constructor(address admin, IERC20 _usdc) ERC20("Secured Private Credit Token", "SPCT") ERC20Permit("SPCT") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        usdc = _usdc;
        // initialize
        _permission[address(0)] = true;
    }

    /**
     * @notice Pause the contract. Revert if already paused.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract. Revert if already unpaused.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Deposit USDC.
     * Emits a `Deposit` event.
     *
     * @param _amount the amount of USDC
     */
    function deposit(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "DEPOSIT_AMOUNT_IS_ZERO");

        usdc.transferFrom(msg.sender, address(this), _amount);
        reserveUSD = reserveUSD.add(_amount);
        totalPooledUSD = totalPooledUSD.add(_amount);

        // Due to different precisions, convert it to SPCT.
        uint256 convertToSPCT = _amount.mul(1e12);

        // calculate fee with SPCT
        if (mintFeeRate == 0) {
            _mint(msg.sender, convertToSPCT);
        } else {
            uint256 feeAmount = convertToSPCT.mul(mintFeeRate).div(FEE_COEFFICIENT);
            uint256 amountAfterFee = convertToSPCT.sub(feeAmount);

            _mint(msg.sender, amountAfterFee);

            if (feeAmount != 0) {
                _mint(feeRecipient, feeAmount);
            }
        }

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Deposit via fiat.
     * Emits a `Deposit` event.
     *
     * @param _amount the amount of USD
     */
    function depositByFiat(address _user, uint256 _amount) external whenNotPaused onlyRole(POOL_MANAGER_ROLE) {
        require(_amount > 0, "DEPOSIT_AMOUNT_IS_ZERO");
        _mint(_user, _amount);
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Redeem SPCT.
     * Emits a `Redeem` event.
     *
     * @param _amount the amount of SPCT.
     */
    function redeem(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "REDEEM_AMOUNT_IS_ZERO");

        // Due to different precisions, convert it to SPCT.
        uint256 convertToUSDC;

        // calculate fee with SPCT
        if (redeemFeeRate == 0) {
            _burn(msg.sender, _amount);
            convertToUSDC = _amount.div(1e12);
        } else {
            uint256 feeAmount = _amount.mul(redeemFeeRate).div(FEE_COEFFICIENT);
            uint256 amountAfterFee = _amount.sub(feeAmount);

            _burn(msg.sender, amountAfterFee);
            convertToUSDC = amountAfterFee.div(1e12);

            if (feeAmount != 0) {
                _transfer(msg.sender, feeRecipient, feeAmount);
            }
        }

        usdc.transfer(msg.sender, convertToUSDC);
        reserveUSD = reserveUSD.sub(convertToUSDC);
        totalPooledUSD = totalPooledUSD.sub(convertToUSDC);

        emit Redeem(msg.sender, _amount);
    }

    /**
     * @notice Redeem via fiat.
     * Emits a `Redeem` event.
     *
     * @param _amount the amount of USD
     */
    function redeemByFiat(address _user, uint256 _amount) external whenNotPaused onlyRole(POOL_MANAGER_ROLE) {
        require(_amount > 0, "REDEEM_AMOUNT_IS_ZERO");
        _burn(_user, _amount);
        emit Redeem(msg.sender, _amount);
    }

    /**
     * @notice Execute USDC to buy private credit.
     * Emits a `Execute` event.
     *
     * @param _amount the amount of USDC (6 decimals).
     */
    function execute(uint256 _amount) external onlyRole(POOL_MANAGER_ROLE) {
        require(_amount > 0, "EXECUTE_AMOUNT_IS_ZERO");

        executedUSD = executedUSD.add(_amount);
        reserveUSD = reserveUSD.sub(_amount);
        usdc.transfer(msg.sender, _amount);

        emit Execute(_amount);
    }

    /**
     * @notice Repay USDC from private credit.
     * Emits a `Repay` event.
     *
     * @param _amount the amount of USDC (6 decimals).
     */
    function repay(uint256 _amount) external onlyRole(POOL_MANAGER_ROLE) {
        if (_amount > executedUSD) revert("REPAY_AMOUNT_EXCEED_EXECUTED_SHARES");

        executedUSD = executedUSD.sub(_amount);
        reserveUSD = reserveUSD.add(_amount);
        usdc.transferFrom(msg.sender, address(this), _amount);

        emit Repay(_amount);
    }

    /**
     * @notice Moves `_amount` tokens from `_sender` to `_recipient`.
     * Emits a `Transfer` event.
     */
    function _update(address _sender, address _recipient, uint256 _amount) internal override {
        require(_permission[_sender], "UNVERIFIED_SENDER");
        require(_permission[_recipient], "UNVERIFIED_RECIPIENT");

        super._update(_sender, _recipient, _amount);
    }

    /**
     * @return true if user in list.
     */
    function isWhitelist(address _user) external view returns (bool) {
        return _permission[_user];
    }

    /**
     * @notice Only KYC users are allow to operate.
     *
     * @param _user user's address.
     */
    function addToWhitelist(address _user) external onlyRole(POOL_MANAGER_ROLE) {
        _permission[_user] = true;
    }

    /**
     * @notice Only KYC users are allow to operate.
     *
     * @param _users array of user addresses.
     */
    function addBatchToWhitelist(address[] calldata _users) external onlyRole(POOL_MANAGER_ROLE) {
        uint256 numUsers = _users.length;
        for (uint256 i; i < numUsers; ++i) {
            _permission[_users[i]] = true;
        }
    }

    /**
     * @notice Only KYC users are allow to operate.
     *
     * @param _user user's address.
     */
    function removeFromWhitelist(address _user) external onlyRole(POOL_MANAGER_ROLE) {
        _permission[_user] = false;
    }

    /**
     * @notice Only KYC users are allow to operate.
     *
     * @param _users array of user addresses.
     */
    function removeBatchFromWhitelist(address[] calldata _users) external onlyRole(POOL_MANAGER_ROLE) {
        uint256 numUsers = _users.length;
        for (uint256 i; i < numUsers; ++i) {
            _permission[_users[i]] = false;
        }
    }

    /**
     * @notice Mint fee.
     *
     * @param newMintFeeRate new mint fee rate.
     */
    function setMintFeeRate(uint256 newMintFeeRate) external onlyRole(POOL_MANAGER_ROLE) {
        require(newMintFeeRate <= maxMintFeeRate, "SHOULD_BE_LESS_THAN_OR_EQUAL_TO_1P");
        mintFeeRate = newMintFeeRate;
        emit MintFeeRateChanged(mintFeeRate);
    }

    /**
     * @notice Redeem fee.
     *
     * @param newRedeemFeeRate new redeem fee rate.
     */
    function setRedeemFeeRate(uint256 newRedeemFeeRate) external onlyRole(POOL_MANAGER_ROLE) {
        require(newRedeemFeeRate <= maxRedeemFeeRate, "SHOULD_BE_LESS_THAN_OR_EQUAL_TO_1P");
        redeemFeeRate = newRedeemFeeRate;
        emit RedeemFeeRateChanged(redeemFeeRate);
    }

    /**
     * @notice Fee recipient address.
     *
     * @param newFeeRecipient new fee recipient address.
     */
    function setFeeRecipient(address newFeeRecipient) external onlyRole(POOL_MANAGER_ROLE) {
        require(newFeeRecipient != address(0), "SET_UP_TO_ZERO_ADDR");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientChanged(feeRecipient);
    }

    /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param token ERC20 token contract address.
     * @param to recipient address.
     * @param amount amount to withdraw.
     */
    function rescueERC20(IERC20 token, address to, uint256 amount) external onlyRole(POOL_MANAGER_ROLE) {
        // If is USDC, check reserve usd amount first.
        if (address(token) == address(usdc)) {
            require(amount <= usdc.balanceOf(address(this)).sub(reserveUSD), "USDC_RESCUE_AMOUNT_EXCEED_DEBIT");
        }
        token.safeTransfer(to, amount);
    }
}