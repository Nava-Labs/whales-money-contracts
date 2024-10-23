// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ISPCTPool {
    error AccessControlBadConfirmation();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error ECDSAInvalidSignature();
    error ECDSAInvalidSignatureLength(uint256 length);
    error ECDSAInvalidSignatureS(bytes32 s);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidSpender(address spender);
    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);
    error EnforcedPause();
    error ExpectedPause();
    error FailedInnerCall();
    error InvalidAccountNonce(address account, uint256 currentNonce);
    error InvalidShortString();
    error SafeERC20FailedOperation(address token);
    error StringTooLong(string str);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed user, uint256 indexed amount);
    event EIP712DomainChanged();
    event Execute(uint256 indexed amount);
    event MintFeeRateChanged(uint256 indexed newFeeRate);
    event Paused(address account);
    event Redeem(address indexed user, uint256 indexed amount);
    event RedeemFeeRateChanged(uint256 indexed newFeeRate);
    event Repay(uint256 indexed amount);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FeeRecipientChanged(address newFeeRecipient);
    event Unpaused(address account);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function FEE_COEFFICIENT() external view returns (uint256);
    function POOL_MANAGER_ROLE() external view returns (bytes32);
    function addBatchToWhitelist(address[] memory _users) external;
    function addToWhitelist(address _user) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function deposit(uint256 _amount) external;
    function depositByFiat(address _user, uint256 _amount) external;
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
    function execute(uint256 _amount) external;
    function executedUSD() external view returns (uint256);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function isWhitelist(address _user) external view returns (bool);
    function maxMintFeeRate() external view returns (uint256);
    function maxRedeemFeeRate() external view returns (uint256);
    function mintFeeRate() external view returns (uint256);
    function name() external view returns (string memory);
    function nonces(address owner) external view returns (uint256);
    function pause() external;
    function paused() external view returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
    function redeem(uint256 _amount) external;
    function redeemByFiat(address _user, uint256 _amount) external;
    function redeemFeeRate() external view returns (uint256);
    function removeBatchFromWhitelist(address[] memory _users) external;
    function removeFromWhitelist(address _user) external;
    function renounceRole(bytes32 role, address callerConfirmation) external;
    function repay(uint256 _amount) external;
    function rescueERC20(address token, address to, uint256 amount) external;
    function reserveUSD() external view returns (uint256);
    function revokeRole(bytes32 role, address account) external;
    function setMintFeeRate(uint256 newMintFeeRate) external;
    function setRedeemFeeRate(uint256 newRedeemFeeRate) external;
    function setFeeRecipient(address newFeeRecipient) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function totalPooledUSD() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function feeRecipient() external view returns (address);
    function unpause() external;
    function usdc() external view returns (address);
}