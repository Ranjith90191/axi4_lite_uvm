# AXI4-Lite Slave — UVM Verification Environment

> A complete, layered UVM testbench for an AXI4-Lite register-based slave peripheral, implementing constrained-random stimulus, functional coverage, SystemVerilog assertions, and a reference model scoreboard.

![Language](https://img.shields.io/badge/Language-SystemVerilog%20%7C%20UVM-blue)
![Simulator](https://img.shields.io/badge/Simulator-Synopsys%20VCS-orange)
![Functional Coverage](https://img.shields.io/badge/Functional%20Coverage-100%25-brightgreen)
![Code Coverage](https://img.shields.io/badge/Code%20Coverage-85.54%25-yellow)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Table of Contents

- [Overview](#overview)
- [DUT Description](#dut-description)
- [Register Map](#register-map)
- [Testbench Architecture](#testbench-architecture)
- [Directory Structure](#directory-structure)
- [Test Suite](#test-suite)
- [Coverage Summary](#coverage-summary)
- [Bug Tracking](#bug-tracking)
- [How to Run](#how-to-run)
- [Tools Used](#tools-used)
- [Author](#author)

---

## Overview

This project delivers a fully layered **UVM verification environment** for an AXI4-Lite slave IP. The slave implements a register-file peripheral with 32-bit data width, 16 registers (MEM_DEPTH=16), and distinct read-only, write-only, and read/write address regions. The testbench exercises all five AXI4-Lite channels — Write Address, Write Data, Write Response, Read Address, and Read Data — under constrained-random and directed stimulus, verifying correct protocol handshaking, register access permissions, byte-enable behavior, and error response generation (SLVERR/DECERR).

The environment was validated against two RTL variants:
- `axi4_lite_slave_real.sv` — the actual DUT under verification (contains injected/real bugs)
- `axi4_lite_slave.sv` — a reference-clean RTL used to validate testbench correctness

---

## DUT Description

The AXI4-Lite slave is a **register-based peripheral** that communicates over the standard five-channel AXI4-Lite bus. Key DUT properties:

| Property | Value |
|---|---|
| Protocol | AXI4-Lite |
| Data Width | 32 bits |
| Address Width | 32 bits |
| Register Depth | 16 (MEM_DEPTH) |
| Valid Byte Address Range | `0x00` – `0x3F` |
| Address Alignment | Word-aligned (ADDR[1:0] == 2'b00) |
| Clock | ACLK (synchronous) |
| Reset | ARESETn (active-low) |

The slave contains separate **Write FSM** (5-state: W_IDLE → W_BOTH → W_ADDR/W_DATA → W_RESP) and **Read FSM** (2-state: R_IDLE → R_DATA), operating independently to support concurrent read/write transactions. Byte-enable partial-word writes are supported via WSTRB[3:0].

### Error Handling

| Condition | Response |
|---|---|
| Valid aligned write to R/W or W/O region | BRESP = OKAY (2'b00) |
| Write to Read-Only region (0x28–0x30) | BRESP = SLVERR (2'b10) |
| Read from Write-Only region (0x34–0x38) | RRESP = SLVERR (2'b10) |
| Unaligned address (ADDR[1:0] ≠ 2'b00) | BRESP/RRESP = SLVERR (2'b10) |
| Address out of range (> 0x3F) | BRESP/RRESP = DECERR (2'b11) |

---

## Register Map

| Byte Address | Word Index | Access Type | Description |
|---|---|---|---|
| 0x00 – 0x24 | 0 – 9 | Read/Write | Normal general-purpose registers |
| 0x28 – 0x30 | 10 – 12 | Read-Only | Status registers |
| 0x34 – 0x38 | 13 – 14 | Write-Only | Command registers |
| 0x3C | 15 | Read/Write | Reserved / normal |
| > 0x3F | — | Invalid | DECERR |

---

## Testbench Architecture

The environment follows standard UVM layering. See [`docs/architecture.md`](docs/architecture.md) for the full block diagram and component descriptions.

```
┌─────────────────────────────────────────────────────────┐
│                      UVM Test                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │                  UVM Environment                  │  │
│  │  ┌──────────────────┐  ┌────────────────────────┐ │  │
│  │  │   AXI4L Agent    │  │      Scoreboard        │ │  │
│  │  │  ┌────────────┐  │  │  (Ref Model Checker)   │ │  │
│  │  │  │  Sequencer │  │  └────────────────────────┘ │  │
│  │  │  ├────────────┤  │  ┌────────────────────────┐ │  │
│  │  │  │   Driver   │  │  │  Functional Coverage   │ │  │
│  │  │  ├────────────┤  │  └────────────────────────┘ │  │
│  │  │  │  Monitor   │  │                             │  │
│  │  │  └────────────┘  │                             │  │
│  │  └──────────────────┘                             │  │
│  └───────────────────────────────────────────────────┘  │
│              AXI4L Interface (SVA Bound)                 │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              DUT: axi4_lite_slave_real.sv           │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Key Components

| Component | File | Role |
|---|---|---|
| Agent | `tb/agents/axi4lite_agent/axi4l_agent.sv` | Encapsulates driver + monitor + sequencer |
| Driver | `tb/agents/axi4lite_agent/axi4l_driver.sv` | Drives all 5 AXI4-Lite channels on DUT pins |
| Monitor | `tb/agents/axi4lite_agent/axi4l_monitor.sv` | Passively observes transactions, sends to scoreboard |
| Scoreboard | `tb/env/axi4l_scoreboard.sv` | Compares DUT response against reference model |
| Reference Model | `tb/env/axi4l_ref_model.sv` | Predicts expected BRESP/RRESP/RDATA per transaction |
| Coverage | `tb/env/axi4l_coverage.sv` | Functional covergroups for address regions, responses, access types |
| Assertions | `tb/assertions/axi4l_assertions.sv` | SVA properties bound to interface |
| Seq Item | `tb/seq_items/axi4l_seq_item.sv` | Transaction object with randomizable fields |
| Interface | `tb/interfaces/axi4l_if.sv` | SystemVerilog interface with clocking blocks |
| Package | `tb/packages/axi4l_package.sv` | Collects all UVM component imports |

---

## Directory Structure

```
.
├── coverage/                        # Coverage reports (HTML summaries)
├── docs/
│   ├── architecture.md              # Testbench architecture + block diagram
│   └── verification_plan.md         # Feature → test → coverage traceability
├── LICENSE
├── README.md
├── rtl/
│   ├── axi4_lite_slave_real.sv      # DUT under verification (contains bugs)
│   └── axi4_lite_slave.sv           # Reference clean RTL (TB sanity check)
├── scripts/
│   └── run_regression.py            # Regression runner script
├── sim/
│   ├── file_list.f                  # Compile filelist
│   ├── Makefile                     # Build and run targets
│   └── regress/
│       └── regress_list.f           # Regression test list
└── tb/
    ├── agents/
    │   └── axi4lite_agent/          # Driver, Monitor, Sequencer, Agent
    ├── assertions/
    │   └── axi4l_assertions.sv      # SVA protocol checks
    ├── defines/
    │   └── axi4l_defines.svh        # Macros and parameters
    ├── env/
    │   ├── axi4l_coverage.sv        # Functional covergroups
    │   ├── axi4l_env.sv             # Top-level UVM environment
    │   ├── axi4l_ref_model.sv       # Golden reference model
    │   └── axi4l_scoreboard.sv      # DUT vs ref model checker
    ├── interfaces/
    │   └── axi4l_if.sv              # AXI4-Lite SV interface
    ├── packages/
    │   └── axi4l_package.sv         # Package imports
    ├── seq_items/
    │   └── axi4l_seq_item.sv        # Transaction class
    ├── sequences/
    │   └── axi4l_sequence.sv        # All sequence classes
    ├── tests/
    │   └── axi4l_test.sv            # Test classes
    └── top/
        └── tb_top.sv                # Top-level testbench module
```

---

## Test Suite

All sequences run via constrained-random stimulus with UVM factory override support.

| Sequence | Transactions | Stimulus Focus | Address Range |
|---|---|---|---|
| `axi4l_write_seq` | 1000 | Write-only transactions | Full random |
| `axi4l_read_seq` | 1000 | Read-only transactions | Full random |
| `axi4l_normal_rw_seq` | 500 | Aligned R/W to valid registers | 0x00–0x24, 0x3C |
| `axi4l_ro_test_seq` | 300 | Access to Read-Only region | 0x28–0x30 |
| `axi4l_wo_test_seq` | 300 | Access to Write-Only region | 0x34–0x38 |
| `axi4l_decerr_seq` | 200 | Out-of-range address (DECERR) | 0x40–0xFFFF |
| `axi4l_unaligned_seq` | 200 | Unaligned access (SLVERR) | ADDR[1:0] ≠ 00 |
| `axi4l_concurrent_seq` | 5000 | Simultaneous R+W same address | Full random |
| `axi4l_fully_rand` | 5000 | Fully randomized (all scenarios) | Full random |
| `axi4l_write_bug_seq` | 10×2 | Bug reproduction — targeted write/read | 0x10 |

> Pass/fail status per test: see [`docs/verification_plan.md`](docs/verification_plan.md)

---

## Coverage Summary

| Coverage Type | Result |
|---|---|
| Functional Coverage | **100%** |
| Code Coverage (overall) | **85.54%** |

Functional covergroups include: address region coverage (R/W, R/O, W/O, DECERR, unaligned), AXI response encoding (OKAY, SLVERR, DECERR), transaction type (read, write, concurrent), and WSTRB byte-enable combinations.

> Detailed coverage report: see `coverage/` directory.
> Remaining 14.46% code coverage gap: tracked in [`docs/verification_plan.md`](docs/verification_plan.md) under Known Gaps.

---

## Bug Tracking

All bugs found during verification are logged and tracked in [GitHub Issues](../../issues) with severity, root cause, and fix status labels.

| ID | Description | Severity | Status | Root Cause |
|---|---|---|---|---|
| [BUG-001](../../issues/1) | _[Placeholder — fill from your actual findings]_ | High | Open | RTL |
| [BUG-002](../../issues/2) | _[Placeholder]_ | Medium | Fixed | RTL |

> Bug log format follows: Severity / Priority / Test that exposed it / Expected vs Actual / Root Cause / Fix commit.
> Bugs found via `axi4l_write_bug_seq` and regression runs on `axi4_lite_slave_real.sv`.

---

## How to Run

### Prerequisites

- Synopsys VCS (tested with [VCS version])
- UVM 1.2 library
- Python 3.x (for regression script)

### Compile and Run a Single Test

```bash
cd sim/
make TEST=axi4l_normal_rw_test
```

### Run Full Regression

```bash
cd sim/
make regress
# or
python3 ../scripts/run_regression.py
```

### Run with Coverage Collection

```bash
cd sim/
make TEST=axi4l_normal_rw_test COV=1
```

### Makefile Targets

| Target | Description |
|---|---|
| `make compile` | Compile RTL + TB |
| `make TEST=<name>` | Run a specific test |
| `make regress` | Run full regression list |
| `make clean` | Remove sim artifacts |
| `make cov_report` | Generate coverage report |

---

## Tools Used

| Tool | Purpose |
|---|---|
| Synopsys VCS | RTL simulation |
| SystemVerilog (IEEE 1800-2017) | RTL and testbench language |
| UVM 1.2 | Verification methodology |
| draw.io | Architecture diagrams |
| Python 3 | Regression automation |
| GitHub Issues | Bug tracking |

---

## Author

**Ranjithraviraj**
- GitHub: [@ranjithraviraj](https://github.com/ranjithraviraj)

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
