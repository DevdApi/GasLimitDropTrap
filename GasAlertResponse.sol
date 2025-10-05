// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title GasAlertResponse
/// @notice Minimal response contract: emits a GasLimitAlert event.
/// Provide both typed and raw-bytes entrypoints for flexibility.
contract GasAlertResponse {
    event GasLimitAlert(uint256 gasUsed, uint256 gasLimit);

    /// @notice Typed entrypoint
    function respondWithGasAlert(uint256 gasUsed, uint256 gasLimit) external {
        emit GasLimitAlert(gasUsed, gasLimit);
    }

    /// @notice Bytes entrypoint: decode & emit
    function respond(bytes calldata data) external {
        (uint256 gasUsed, uint256 gasLimit) = abi.decode(data, (uint256, uint256));
        emit GasLimitAlert(gasUsed, gasLimit);
    }
}
