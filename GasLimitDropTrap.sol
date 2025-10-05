// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITrap } from "drosera-contracts/interfaces/ITrap.sol";

/// @title GasLimitDropTrap
/// @notice Minimal Drosera trap tracking gas usage and limit
contract GasLimitDropTrap is ITrap {
    uint256 public lastBlockGasUsed;
    uint256 public lastBlockGasLimit;

    event GasDataCollected(uint256 gasUsed, uint256 gasLimit);

    /// @notice Collect gas metrics (dryrun-safe)
    /// @dev Must match ITrap interface exactly
    function collect() external view override returns (bytes memory) {
        return abi.encode(lastBlockGasUsed, lastBlockGasLimit);
    }

    /// @notice Persist metrics (for live use via forge or cast)
    function collectTyped(uint256 gasUsed, uint256 gasLimit) external {
        lastBlockGasUsed = gasUsed;
        lastBlockGasLimit = gasLimit;
        emit GasDataCollected(gasUsed, gasLimit);
    }

    /// @notice Deterministic check for Drosera (compliant with ITrap)
    /// @dev Accepts array of encoded arguments
    /// returns (shouldRespond, encodedReason)
    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        bool result;

        if (data.length == 1) {
            // Single threshold input
            uint256 threshold = abi.decode(data[0], (uint256));
            // Compare threshold against itself (demo logic)
            result = threshold > 0;
        } else if (data.length == 2) {
            // GasUsed and GasLimit pair
            (uint256 gasUsed, uint256 gasLimit) = abi.decode(data[0], (uint256, uint256));
            if (gasLimit == 0) {
                result = false;
            } else {
                result = gasUsed * 100 > gasLimit * 90; // >90% usage
            }
        } else {
            result = false;
        }

        return (result, abi.encode(result));
    }
}
