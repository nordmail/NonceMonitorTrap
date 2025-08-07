// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract NonceMonitorTrap is ITrap {
    address public constant target = 0xbe5932ea270bA07bD88c74F102329f45bc9C125C;
    uint256 public constant maxNormalIncrement = 5;

    function collect() external view override returns (bytes memory) {
        return abi.encode(target.balance, uint256(0));
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        require(data.length >= 2, "Insufficient data");

        (, uint256 prevNonce) = abi.decode(data[1], (uint256, uint256));
        (uint256 currentBalance, uint256 currentNonce) = abi.decode(data[0], (uint256, uint256));

        uint256 nonceDifference = currentNonce > prevNonce ? currentNonce - prevNonce : 0;

        if (nonceDifference > maxNormalIncrement) {
            return (true, abi.encode("Nonce jump detected", nonceDifference, currentBalance));
        }

        return (false, "");
    }
}
