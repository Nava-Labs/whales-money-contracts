// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IswUSD {
    error AccessControlBadConfirmation();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidSpender(address spender);
    error ERC4626ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);
    error ERC4626ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);
    error FailedInnerCall();
    error InvalidAccountNonce(address account, uint256 currentNonce);
    error InvalidShortString();
    error MathOverflowedMulDiv();
    error ReentrancyGuardReentrantCall();
    error SafeERC20FailedOperation(address token);
    error StringTooLong(string str);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event CDPeriodChanged(uint256 newCDPeriod, uint256 timestamp);
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event EIP712DomainChanged();
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event VestingPeriodChanged(uint256 newCDPeriod, uint256 timestamp);
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );
    event YieldReceived(uint256 amount, uint256 timestamp);

    function CD(address) external view returns (uint256 time, uint256 amount);
    function CDAssets(uint256 _assets) external returns (uint256 _shares);
    function CDPeriod() external view returns (uint24);
    function CDShares(uint256 _shares) external returns (uint256 _assets);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function MAX_CD_PERIOD() external view returns (uint24);
    function POOL_MANAGER_ROLE() external view returns (bytes32);
    function YIELD_MANAGER_ROLE() external view returns (bytes32);
    function addBatchToBlacklist(address[] memory _users) external;
    function addToBlacklist(address _user) external;
    function addYield(uint256 _amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function asset() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function decimals() external pure returns (uint8);
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
    function flat() external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function getUnvestedAmount() external view returns (uint256);
    function grantRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function isBlacklist(address _user) external view returns (bool);
    function lastDistributionTime() external view returns (uint256);
    function maxDeposit(address) external view returns (uint256);
    function maxMint(address) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);
    function mint(uint256 shares, address receiver) external returns (uint256);
    function name() external view returns (string memory);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
    function pooledWUSD() external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewMint(uint256 shares) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);
    function redeem(uint256 shares, address receiver, address _owner) external returns (uint256);
    function removeBatchFromBlacklist(address[] memory _users) external;
    function removeFromBlacklist(address _user) external;
    function renounceRole(bytes32 role, address callerConfirmation) external;
    function rescueERC20(address token, address to, uint256 amount) external;
    function revokeRole(bytes32 role, address account) external;
    function setNewCDPeriod(uint24 newCDPeriod) external;
    function setNewVestingPeriod(uint256 newPeriod) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function unstake() external;
    function vestingAmount() external view returns (uint256);
    function vestingPeriod() external view returns (uint256);
    function withdraw(uint256 assets, address receiver, address _owner) external returns (uint256);
}
