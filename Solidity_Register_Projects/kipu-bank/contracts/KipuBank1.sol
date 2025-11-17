// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title KipuBank - simple vault per-user with global cap and per-tx withdraw limit
/// @author Maria Eduarda
/// @notice Minimal, well-documented contract for storing native tokens per user
/// @dev Follows checks-effects-interactions, uses custom errors and NatSpec comments

/// @notice Reverted when a deposit would exceed the global bank cap
error ExceedsBankCap(uint256 requested, uint256 available);

/// @notice Reverted when a withdraw amount exceeds the per-transaction limit 
error ExceedsPerTxLimit(uint256 requested, uint256 limit);

/// @notice Reverted when an account attempts to withdraw more than its balance
error InsufficientBalance(address account, uint256 requested, uint256 balance);

/// @notice Reverted when a native transfer {to} fails
error TransferFailed(address to, uint256 amount);

/// @notice Reverted when a zero value is used where not allowed
error ZeroValueNotAllowed();

/// @notice Reverted when constructor parameters are invalid
error InvalidInitParams();

contract KipuBank {
    /// @notice Global cap for total deposits to the bank (immutable)
    uint256 public immutable bankCap;

    /// @notice Withdraw limit per transaction for users (immutable)
    uint256 public immutable perTxLimit;

    /// @notice Total deposits currently held in contract (in wei)
    uint256 public totalDeposits;

    /// @notice Mapping of user => balance (in wei)
    mapping(address => uint256) private balances;

    /// @notice Number of deposits per user
    mapping(address => uint256) private depositCount;

    /// @notice Number of withdrawals per user
    mapping(address => uint256) private withdrawCount;

    /// @notice Emitted when a user deposits ETH
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);

    /// @notice Emitted when a user withdraws ETH
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance);

    /// @param _bankCap total allowed deposits at deployment (in wei)
    /// @param _perTxLimit max allowed withdraw per transaction (wei)
    constructor(uint256 _bankCap, uint256 _perTxLimit) {
        // preferir usar custom errors ao invés de require com string
        if(_bankCap == 0 || _perTxLimit == 0) revert InvalidInitParams(); 
        bankCap = _bankCap;
        perTxLimit = _perTxLimit;
    }

    // Deposits:
    /// @notice Deposit native ETH into your personal vault
    /// @dev Reverts with ExceedsBankCap if bank would exceed cap
    function deposit() external payable {
        _handleDeposit(msg.sender, msg.value);
    }

    /// @dev Internal shared deposit handler used by deposit() and receive()
    function _handleDeposit(address from, uint256 amount) private {
        if(amount == 0) revert ZeroValueNotAllowed();

        // checks
        uint256 newTotal = totalDeposits + amount;
        if (newTotal > bankCap) revert ExceedsBankCap(amount, bankCap - totalDeposits);

        // effects
        balances[from] += amount;
        totalDeposits = newTotal;
        depositCount[from]++;

        // interaction: emit event (no external calls)
        emit Deposit(from, amount, balances[from]);
    }

    /// @notice Accept plain ETH transfers as deposits
    /// @dev forwards to internal deposit handler so that direct sends follow same rules
    receive() external payable {
        _handleDeposit(msg.sender, msg.value);
    }

    fallback() external payable {
        // optionally accept fallback as deposit as well
        _handleDeposit(msg.sender, msg.value); 
    }

    // Withdrawals:

    /// @notice Withdraw up to perTxLimit from your vault
    /// @param amount in wei to withdraw
    /// @dev Uses checks-effects-interactions and safe call transfer
    function withdraw(uint256 amount) external {
        if(amount == 0) revert ZeroValueNotAllowed();
        if(amount > perTxLimit) revert ExceedsPerTxLimit(amount, perTxLimit);

        uint256 bal = balances[msg.sender];
        if(amount > bal) revert InsufficientBalance(msg.sender, amount, bal);

        // effects
        balances[msg.sender] = bal - amount;
        totalDeposits -= amount;
        withdrawCount[msg.sender]++;

        // interaction: safe send using call
        _safeSend(payable(msg.sender), amount);

        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

    /// @dev Internal safe send using call, reverts with TransferFailed on error
    function _safeSend(address payable to, uint256 amount) private {
        (bool success, ) = to.call{value: amount} ("");
        if (!success) revert TransferFailed(to, amount);
    }

    // View / Getters:

    /// @notice Returns the balance of 'account' in wei
    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }

    /// @notice Returns deposit and withdraw counts for an account
    function getCounts(address account) external view returns (uint256 deposits, uint256 withdraws) {
        return (depositCount[account], withdrawCount[account]);
    }

}