// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20,ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeMath} from "../utils/SafeMath.sol";
import {USDbFlat} from "./USDbFlat.sol";

/**
 * @title Staked USDb for getting yield.
 */
contract SUSDb is AccessControl, ReentrancyGuard, ERC20Permit, ERC4626 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant POOL_MANAGER_ROLE = keccak256("POOL_MANAGER_ROLE");
    bytes32 public constant YIELD_MANAGER_ROLE = keccak256("YIELD_MANAGER_ROLE");

    // Max withdraw cd time.
    uint24 public constant MAX_CD_PERIOD = 90 days;
    uint24 public CDPeriod;
    // It depends on how long we get the yield from off-chain. (Default is 30 days)
    uint256 public vestingPeriod = 30 days;

    uint256 public pooledUSDb;
    uint256 public vestingAmount;
    uint256 public lastDistributionTime;

    USDbFlat public immutable flat;

    struct UserCD {
        uint256 time;
        uint256 amount;
    }

    mapping(address => UserCD) public CD;
    // Blacklist
    mapping(address => bool) private _blacklist;

    event YieldReceived(uint256 indexed amount);
    event CDPeriodChanged(uint256 indexed newCDPeriod);
    event VestingPeriodChanged(uint256 indexed newCDPeriod);
    event CDUnstake(address indexed user, uint256 indexed amount, uint256 indexed unstakeEndedAt);
    event Unstake(address indexed user, uint256 indexed amount);

    constructor(address _admin, IERC20 _asset, uint24 _CDPeriod)
        ERC20("Staked USDb", "sUSDb")
        ERC4626(_asset)
        ERC20Permit("sUSDb")
    {
        require(_CDPeriod < MAX_CD_PERIOD, "CDPERIOD_SHOULD_BE_LESS_THAN_90_DAYS");
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        CDPeriod = _CDPeriod;
        flat = new USDbFlat(address(this), _asset);
    }

    /**
     * @notice Add Yield(USDb) to this contract.
     * Emits a `YieldReceived` event.
     */
    function addYield(uint256 _amount) external onlyRole(YIELD_MANAGER_ROLE) {
        require(_amount > 0, "TRANSFER_AMOUNT_IS_ZERO");
        require(totalSupply() > 1 ether, "NOT_ENOUGH_TOTAL_STAKED_USDB");
        _updateVestingAmount(_amount);
        pooledUSDb = pooledUSDb.add(_amount);
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), _amount);
        emit YieldReceived(_amount);
    }

    /**
     * @notice set new CD period.
     *
     * @param newCDPeriod new CD period.
     */
    function setNewCDPeriod(uint24 newCDPeriod) external onlyRole(POOL_MANAGER_ROLE) {
        require(newCDPeriod < MAX_CD_PERIOD, "SHOULD_BE_LESS_THAN_MAX_CD_PERIOD");

        CDPeriod = newCDPeriod;
        emit CDPeriodChanged(newCDPeriod);
    }

    /**
     * @notice set new vesting period.
     *
     * @param newPeriod new vesting period.
     */
    function setNewVestingPeriod(uint256 newPeriod) external onlyRole(POOL_MANAGER_ROLE) {
        require(newPeriod > 0 && newPeriod < type(uint256).max, "SHOULD_BE_LESS_THAN_UINT256_MAX_AND_GREATER_THAN_ZERO");
        vestingPeriod = newPeriod;
        emit VestingPeriodChanged(newPeriod);
    }

    /**
     * @return true if user in list.
     */
    function isBlacklist(address _user) external view returns (bool) {
        return _blacklist[_user];
    }

    function addToBlacklist(address _user) external onlyRole(POOL_MANAGER_ROLE) {
        _blacklist[_user] = true;
    }

    function addBatchToBlacklist(address[] calldata _users) external onlyRole(POOL_MANAGER_ROLE) {
        uint256 numUsers = _users.length;
        for (uint256 i; i < numUsers; ++i) {
            _blacklist[_users[i]] = true;
        }
    }

    function removeFromBlacklist(address _user) external onlyRole(POOL_MANAGER_ROLE) {
        _blacklist[_user] = false;
    }

    function removeBatchFromBlacklist(address[] calldata _users) external onlyRole(POOL_MANAGER_ROLE) {
        uint256 numUsers = _users.length;
        for (uint256 i; i < numUsers; ++i) {
            _blacklist[_users[i]] = false;
        }
    }

    /**
     * @notice Total vested USDb in this contract.
     * @dev To prevent ERC4626 Inflation Attacks. We use pooledUSDb to calculate totalAssets instead of balanceOf().
     *
     * https://blog.openzeppelin.com/a-novel-defense-against-erc4626-inflation-attacks
     *
     */
    function totalAssets() public view override returns (uint256) {
        uint256 unvested = getUnvestedAmount();
        return pooledUSDb.sub(unvested);
    }

    /**
     * @dev Add mode check to {IERC4626-withdraw}.
     */
    function withdraw(uint256 assets, address receiver, address _owner) public virtual override returns (uint256) {
        require(CDPeriod == 0, "ERC4626_MODE_ON");
        return super.withdraw(assets, receiver, _owner);
    }

    /**
     * @dev Add mode check to {IERC4626-redeem}.
     */
    function redeem(uint256 shares, address receiver, address _owner) public virtual override returns (uint256) {
        require(CDPeriod == 0, "ERC4626_MODE_ON");
        return super.redeem(shares, receiver, _owner);
    }

    /**
     * @notice Used to claim USDb after CD has finished.
     * @dev Works on both mode.
     */
    function unstake() external {
        UserCD storage userCD = CD[msg.sender];
        require(block.timestamp >= userCD.time || CDPeriod == 0, "UNSTAKE_FAILED");

        uint256 amountToWithdraw = userCD.amount;
        userCD.time = 0;
        userCD.amount = 0;

        flat.withdraw(msg.sender, amountToWithdraw);

        emit Unstake(msg.sender, amountToWithdraw);
    }

    /**
     * @notice Starts withdraw CD with assets.
     */
    function CDAssets(uint256 _assets) external returns (uint256 _shares) {
        require(CDPeriod > 0, "CD_MODE_ON");
        require(_assets <= maxWithdraw(msg.sender), "WITHDRAW_AMOUNT_EXCEEDED");

        _shares = previewWithdraw(_assets);

        uint256 unstakeEndedAt = block.timestamp + CDPeriod;
        CD[msg.sender].time = unstakeEndedAt;
        CD[msg.sender].amount += _assets;

        _withdraw(msg.sender, address(flat), msg.sender, _assets, _shares);

        emit CDUnstake(msg.sender, _assets, unstakeEndedAt);
    }

    /**
     * @notice Starts withdraw CD with shares.
     */
    function CDShares(uint256 _shares) external returns (uint256 _assets) {
        require(CDPeriod > 0, "CD_MODE_ON");
        require(_shares <= maxRedeem(msg.sender), "WITHDRAW_AMOUNT_EXCEEDED");

        _assets = previewRedeem(_shares);

        uint256 unstakeEndedAt = block.timestamp + CDPeriod;
        CD[msg.sender].time = unstakeEndedAt;
        CD[msg.sender].amount += _assets;

        _withdraw(msg.sender, address(flat), msg.sender, _assets, _shares);

        emit CDUnstake(msg.sender, _assets, unstakeEndedAt);
    }

    function getUnvestedAmount() public view returns (uint256) {
        uint256 timeGap = block.timestamp.sub(lastDistributionTime);

        // If all vested
        if (timeGap >= vestingPeriod) {
            return 0;
        } else {
            uint256 unvestedAmount = ((vestingPeriod.sub(timeGap)).mul(vestingAmount)).div(vestingPeriod);
            return unvestedAmount;
        }
    }

    /**
     * @dev ERC4626 and ERC20 define function with same name and parameter types.
     */
    function decimals() public pure override(ERC4626, ERC20) returns (uint8) {
        return 18;
    }

    /**
     * @dev Add nonReetrant and pooledUSDb calculation.
     */
    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares)
        internal
        override
        nonReentrant
    {
        require(_assets > 0, "ASSETS_IS_ZERO");
        require(_shares > 0, "SHARES_IS_ZERO");
        require(!_blacklist[_receiver], "RECIPIENT_IN_BLACKLIST");

        super._deposit(_caller, _receiver, _assets, _shares);
        pooledUSDb = pooledUSDb.add(_assets);
    }

    function _withdraw(address _caller, address _receiver, address _owner, uint256 _assets, uint256 _shares)
        internal
        override
        nonReentrant
    {
        require(_assets > 0, "ASSETS_IS_ZERO");
        require(_shares > 0, "SHARES_IS_ZERO");

        pooledUSDb = pooledUSDb.sub(_assets);
        super._withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    function _updateVestingAmount(uint256 _amount) internal {
        require(getUnvestedAmount() == 0, "UNVESTING_IS_NOT_ZERO");

        vestingAmount = _amount;
        lastDistributionTime = block.timestamp;
    }

    function _update(address from, address to, uint256 amount) internal virtual override {
        require(!_blacklist[from], "SENDER_IN_BLACKLIST");
        require(!_blacklist[to], "RECIPIENT_IN_BLACKLIST");
        super._update(from, to, amount);
    }

    function rescueERC20(IERC20 token, address to, uint256 amount) external onlyRole(POOL_MANAGER_ROLE) {
        // If is USDb, check pooled amount first.
        if (address(token) == asset()) {
            require(amount <= token.balanceOf(address(this)).sub(pooledUSDb), "USDB_RESCUE_AMOUNT_EXCEED_DEBIT");
        }
        token.safeTransfer(to, amount);
    }
}
