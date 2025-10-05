#README- GasLimitDropTrap

A minimal Drosera “trap” contract that tracks gas usage vs gas limit and triggers when usage passes a threshold.
This repository includes the Solidity trap, a corresponding Foundry test, and example `cast` calls to interact with the trap.

---

## 📦 Repository Structure

```
.
├── src
│   └── GasLimitDropTrap.sol
├── test
│   └── GasLimitDropTrap.t.sol
├── drosera.toml
└── README.md
```

* `src/GasLimitDropTrap.sol` — the trap contract.
* `test/GasLimitDropTrap.t.sol` — Foundry test suite for the trap.
* `drosera.toml` — Drosera config for running dryruns / live.
* `README.md` — this document.

---

## Trap Overview & Purpose

The **GasLimitDropTrap** is a simple Drosera trap whose goal is:

1. **Record** the last observed `gasUsed` and `gasLimit` (via an external script or operator).
2. Provide a deterministic `collect()` method (view-only) so Drosera’s dryrun can safely read those stored values.
3. Offer a `shouldRespond(...)` logic that determines whether the trap should “fire” (respond) based on either:

   * A threshold (if provided), or
   * The stored gas usage crossing a 90% usage boundary, or
   * Input gas pair arguments.

This trap acts like a sensor: it doesn’t itself detect the gas — it simply stores metrics and lets Drosera’s orchestration decide when to act.

### Key Features

* `collect()` is **view-only** and never mutates state (safe under Drosera dryrun).
* `collectTyped(gasUsed, gasLimit)` is the live helper to persist data.
* `shouldRespond(bytes[] calldata args)` is a pure deterministic function used by Drosera to evaluate conditions.
* Modular logic to compare:

  * `lastBlockGasUsed > threshold`
  * `gasUsed * 100 > gasLimit * 90` (i.e. > 90% usage)
  * fallback behavior if no args provided

---

## 🧪 Foundry Test (GasLimitDropTrap.t.sol)

Here’s a sketch of how a Foundry test could look. Adapt yours accordingly.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GasLimitDropTrap.sol";

contract GasLimitDropTrapTest is Test {
    GasLimitDropTrap trap;

    function setUp() public {
        trap = new GasLimitDropTrap();
    }

    function testInitialCollect() public {
        // At initial state, both values are zero
        bytes memory encoded = trap.collect();
        (uint256 u, uint256 l) = abi.decode(encoded, (uint256, uint256));
        assertEq(u, 0);
        assertEq(l, 0);
    }

    function testCollectTypedAndRespondThreshold() public {
        // Persist some metrics
        trap.collectTyped(95, 100);
        bytes memory encoded = trap.collect();
        (uint256 u, uint256 l) = abi.decode(encoded, (uint256, uint256));
        assertEq(u, 95);
        assertEq(l, 100);

        // Should respond if threshold = 90
        bytes ;
        args[0] = abi.encode(uint256(90));
        (bool resp, bytes memory ret) = trap.shouldRespond(args);
        assertTrue(resp);

        // Should not respond if threshold higher
        args[0] = abi.encode(uint256(96));
        (resp, ) = trap.shouldRespond(args);
        assertFalse(resp);
    }

    function testShouldRespondGasPair() public {
        // Provide input gasUsed/gasLimit directly
        bytes ;
        args[0] = abi.encode(uint256(91), uint256(100));
        (bool resp, ) = trap.shouldRespond(args);
        assertTrue(resp);

        args[0] = abi.encode(uint256(89), uint256(100));
        (resp, ) = trap.shouldRespond(args);
        assertFalse(resp);
    }
}
```

This test suite covers:

* Default collect behavior
* Persisting via `collectTyped`
* `shouldRespond` by threshold
* `shouldRespond` by gas pair semantics

Run via:

```bash
forge test
```

---

## 💻 `cast` / Script Calls for Interacting with Trap

Here are example `cast` commands to call your trap on-chain or via a local testnet.

Assume you have environment variables or configuration for the trap’s address and RPC target.

### 1. `collectTyped` (persist metrics)

```bash
cast send \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  <TRAP_ADDRESS> \
  "collectTyped(uint256,uint256)" \
  9500000 10000000
```

This will store `(gasUsed = 9_500_000, gasLimit = 10_000_000)` into your trap.

### 2. `collect()` (view read via RPC)

```bash
cast call \
  --rpc-url $RPC_URL \
  <TRAP_ADDRESS> \
  "collect()"  
```

This returns `bytes` (ABI-encoded) of two `uint256`, e.g. `"0x…"` which you then decode:

```bash
cast call ... collect() | cast --decode "uint256,uint256"
```

### 3. `shouldRespond(...)` with threshold

```bash
cast call \
  --rpc-url $RPC_URL \
  <TRAP_ADDRESS> \
  "shouldRespond(bytes[])" \
  '["0x000000000000000000000000000000000000000000000000000000000000005a"]'
```

Here `0x5a` = 90 decimal. It returns `(bool, bytes)`, e.g. `(true, "0x...")`.

### 4. `shouldRespond(...)` with gas pair

```bash
# encode two uint256 arguments into a single bytes blob
DATA=$(cast abi-encode "uint256,uint256" 9500000 10000000)
cast call --rpc-url $RPC_URL <TRAP_ADDRESS> "shouldRespond(bytes[])" "[$DATA]"
```

This will return whether `9500000 * 100 > 10000000 * 90`.

---

## ✅ Getting Started

1. Clone the repository
2. Install dependencies (e.g. `npm install`, `forge install`)
3. Build:

   ```bash
   forge build
   ```
4. Run tests:

   ```bash
   forge test
   ```
5. Use `drosera dryrun` to validate trap under Drosera environment
6. Use `cast` commands (or your scripts) to feed data and evaluate the trap

---

## 📝 Notes & Caveats

* The trap’s `collect()` is `view` only; it doesn’t mutate state. This ensures Drosera dryruns are safe.
* The `shouldRespond(...)` function must be **pure / deterministic** (no reading from block or state) to avoid dryrun unpredictability.
* The gas threshold logic uses the formula:
  `gasUsed * 100 > gasLimit * 90`
  i.e. usage strictly greater than 90%.
* You may extend or customize it: e.g. different thresholds, multiple conditions, combining other state checks.

---

