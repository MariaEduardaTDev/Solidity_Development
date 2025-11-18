# KipuBank

KipuBank is a study-oriented Ethereum smart contract designed to simulate a minimal on-chain vault system.  
It allows users to store and withdraw ETH safely while enforcing transaction limits and tracking individual activity.  
This project focuses on learning Solidity best practices, state management, and secure ETH handling.

## What the Contract Does

- Stores ETH on behalf of users.
- Tracks each user’s balance and transaction history.
- Enforces a **per-transaction withdrawal limit**.
- Enforces a **maximum total deposit capacity** (`bankCap`).
- Rejects unexpected ETH transfers for safety (`fallback` protection).
- Provides read-only functions for inspecting balances, counts, and global contract state.

This contract is intentionally simple and intended for technical learning, experimentation, and improving secure smart contract development skills.

## Key Functions

### Deposit
- Uses `deposit()` and requires ETH to be sent in the transaction value.
- Updates user balance, total deposits, and deposit count.

### Withdraw
- Uses `withdraw(uint256 amount)` with validation against:
  - user balance
  - per-transaction limits
- Transfers ETH safely using `call`.

### Read-Only Utilities
- `getBalance(address)` – user internal balance.  
- `getCounts(address)` – number of deposits/withdrawals.  
- `totalDeposits()` – global total in the vault.  
- `bankCap()` / `perTxLimit()` – system limits.

## Deployment (Remix)

1. Open **Remix**: https://remix.ethereum.org  
2. Create a new file `KipuBank.sol` and paste the contract code.  
3. Compile using Solidity **0.8.x**.  
4. Deploy using:
   - **Remix VM** for testing, or  
   - **Injected Provider (MetaMask)** for using a real testnet.

No constructor parameters are required.

## Interaction (Remix)

- To **deposit**, set the ETH amount in the "Value" field → click **deposit()**.  
- To **withdraw**, specify the amount in wei → click **withdraw**.  
- Use the view functions to check balances, counts, or system limits.

## Notes

- This contract is for **educational purposes only** and not intended for production use.  
- It demonstrates secure patterns such as checks-effects-interactions, limited accept paths for ETH, and explicit fallback handling.

## License
MIT

