
# Nonce Spike Monitor Trap — Drosera Trap

## 🎯 Objective

Create a Drosera trap that monitors the **nonce** of a specified wallet and triggers an alert if the nonce increases by more than a given threshold within a short block window — useful for detecting mass automated transactions, bot activity, or suspicious wallet usage.

---

## 🛑 Problem

If a wallet suddenly sends many transactions (e.g., nonce jumps by >5 within 10 blocks), it could indicate automated behavior, compromised access, or attack attempts. This trap ensures quick detection.

---

## ⚙️ Trap Logic Summary

**Trap contract:** `NonceMonitorTrap.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external view returns (bool, bytes memory);
}

contract NonceMonitorTrap is ITrap {
    address public constant target = 0xbe5932ea270bA07bD88c74F102329f45bc9C125C;
    uint256 public constant maxNormalIncrement = 5;

    function collect() external view override returns (bytes memory) {
        return abi.encode(target.balance, target.nonce);
    }

    function shouldRespond(bytes[] calldata data) external view override returns (bool, bytes memory) {
        require(data.length >= 2, "Insufficient data");

        (uint256 prevBalance, uint256 prevNonce) = abi.decode(data[1], (uint256, uint256));
        (uint256 currentBalance, uint256 currentNonce) = abi.decode(data[0], (uint256, uint256));

        uint256 nonceDiff = currentNonce > prevNonce ? currentNonce - prevNonce : 0;

        if (nonceDiff > maxNormalIncrement) {
            return (true, abi.encode("Nonce jump detected", nonceDiff, currentBalance));
        }

        return (false, "");
    }
}
```

---

## 📡 Response Contract: `NonceAlertReceiver.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NonceAlertReceiver {
    event NonceAlert(string message, uint256 jumpSize, uint256 currentBalance);

    function logNonceAnomaly(bytes calldata data) external {
        (string memory message, uint256 jumpSize, uint256 currentBalance) =
            abi.decode(data, (string, uint256, uint256));
        emit NonceAlert(message, jumpSize, currentBalance);
    }
}
```

---

## 🛠 Deployment & Setup Instructions

### 1. Compile with Foundry

```bash
forge build
```

### 2. Deploy Contracts

```bash
forge create src/NonceMonitorTrap.sol:NonceMonitorTrap \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com \
  --private-key 0xYOUR_KEY

forge create src/NonceAlertReceiver.sol:NonceAlertReceiver \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com \
  --private-key 0xYOUR_KEY
```

### 3. Edit `drosera.toml`

```toml
[traps.nonceMonitorTrap]
path = "out/NonceMonitorTrap.sol/NonceMonitorTrap.json"
response_contract = "<NonceAlertReceiver address>"
response_function = "logNonceAnomaly"
block_sample_size = 10
private_trap = true
whitelist = ["0xYOUR_ADDRESS"]
```

### 4. Apply Trap

```bash
DROSERA_PRIVATE_KEY=0xYOUR_KEY drosera apply
```

---

## ✅ Testing

- Send multiple transactions from the monitored address.
- Monitor logs with:

```bash
journalctl -u drosera-operator | grep ShouldRespond
```

- Example log line:

```
ShouldRespond='true' trap_address=0x... block_number=...
```

---

## 🧩 Author

- Author: @nordmail
- Created: August 2025
- License: MIT
