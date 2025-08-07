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
