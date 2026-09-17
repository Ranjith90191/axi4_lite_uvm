# Verification Plan — AXI4-Lite Slave

**DUT:** `axi4_lite_slave_real.sv`
**Spec:** `AXI4-Lite_Master-Slave_IP_updated.pdf`
**Simulator:** Synopsys VCS
**Methodology:** UVM 1.2
**Author:** Ranjithraviraj

---

## Verification Closure Criteria

| Metric | Target | Achieved |
|---|---|---|
| Functional Coverage | 100% | ✅ 100% |
| Code Coverage | ≥ 90% | 🔶 85.54% |
| All directed tests passing | 100% | _[fill]_ |
| All SVA assertions passing | 0 failures | _[fill]_ |
| Regression passing | 100% | _[fill]_ |

---

## Feature Verification Traceability

### 1. Write Transactions

| Feature | Spec Ref | Sequence | Covergroup | Status |
|---|---|---|---|---|
| Basic write to R/W register | Sec 10, 11 | `axi4l_write_seq`, `axi4l_normal_rw_seq` | addr_region_cg: RW | _[PASS/FAIL]_ |
| Write address handshake (AWVALID/AWREADY) | Sec 4, 11 | All write sequences | — | _[PASS/FAIL]_ |
| Write data handshake (WVALID/WREADY) | Sec 5, 11 | All write sequences | — | _[PASS/FAIL]_ |
| Write response (BVALID/BREADY) | Sec 6, 11 | All write sequences | bresp_cg: OKAY | _[PASS/FAIL]_ |
| Write to Read-Only region → SLVERR | Sec 20 | `axi4l_ro_test_seq` | bresp_cg: SLVERR | _[PASS/FAIL]_ |
| Write to Write-Only region → OKAY | Sec 10, 20 | `axi4l_wo_test_seq` | addr_region_cg: WO | _[PASS/FAIL]_ |
| Write to out-of-range address → DECERR | Sec 9, 20 | `axi4l_decerr_seq` | bresp_cg: DECERR | _[PASS/FAIL]_ |
| Unaligned write address → SLVERR | Sec 10, 20 | `axi4l_unaligned_seq` | bresp_cg: SLVERR | _[PASS/FAIL]_ |
| Byte-enable (WSTRB) partial write | Sec 17 | `axi4l_fully_rand` | wstrb_cg | _[PASS/FAIL]_ |
| Address and data may arrive in any order | Sec 11 | `axi4l_concurrent_seq` | txn_type_cg | _[PASS/FAIL]_ |

### 2. Read Transactions

| Feature | Spec Ref | Sequence | Covergroup | Status |
|---|---|---|---|---|
| Basic read from R/W register | Sec 10, 12 | `axi4l_read_seq`, `axi4l_normal_rw_seq` | addr_region_cg: RW | _[PASS/FAIL]_ |
| Read address handshake (ARVALID/ARREADY) | Sec 7, 12 | All read sequences | — | _[PASS/FAIL]_ |
| Read data response (RVALID/RREADY) | Sec 8, 12 | All read sequences | rresp_cg: OKAY | _[PASS/FAIL]_ |
| Read from Read-Only region → OKAY + correct data | Sec 10 | `axi4l_ro_test_seq` | addr_region_cg: RO | _[PASS/FAIL]_ |
| Read from Write-Only region → SLVERR | Sec 20 | `axi4l_wo_test_seq` | rresp_cg: SLVERR | _[PASS/FAIL]_ |
| Read from out-of-range address → DECERR | Sec 9, 20 | `axi4l_decerr_seq` | rresp_cg: DECERR | _[PASS/FAIL]_ |
| Unaligned read address → SLVERR | Sec 10, 20 | `axi4l_unaligned_seq` | rresp_cg: SLVERR | _[PASS/FAIL]_ |
| Read data correctness (readback after write) | Sec 10 | `axi4l_normal_rw_seq` | — | _[PASS/FAIL]_ |

### 3. Concurrent / Parallel Operation

| Feature | Spec Ref | Sequence | Covergroup | Status |
|---|---|---|---|---|
| Simultaneous read and write transaction | Sec 18 | `axi4l_concurrent_seq` | txn_type_cg: concurrent | _[PASS/FAIL]_ |
| Read and write FSMs operate independently | Sec 18 | `axi4l_concurrent_seq`, `axi4l_fully_rand` | — | _[PASS/FAIL]_ |

### 4. Protocol / Handshake Compliance

| Feature | Spec Ref | Assertion | Status |
|---|---|---|---|
| AWVALID stable until AWREADY | AXI spec rule | `assert_awvalid_stable` | _[PASS/FAIL]_ |
| WVALID stable until WREADY | AXI spec rule | `assert_wvalid_stable` | _[PASS/FAIL]_ |
| ARVALID stable until ARREADY | AXI spec rule | `assert_arvalid_stable` | _[PASS/FAIL]_ |
| BVALID follows completed write | Sec 11 | `assert_bvalid_after_write` | _[PASS/FAIL]_ |
| No X on BRESP/RRESP when VALID high | — | `assert_no_x_on_resp` | _[PASS/FAIL]_ |

### 5. Reset Behavior

| Feature | Spec Ref | Sequence | Status |
|---|---|---|---|
| All VALID signals cleared on ARESETn | Sec 21 | _[add reset sequence]_ | _[PASS/FAIL]_ |
| FSMs return to IDLE on reset | Sec 21 | _[add reset sequence]_ | _[PASS/FAIL]_ |
| Internal registers zeroed on reset | Sec 21 | _[add reset sequence]_ | _[PASS/FAIL]_ |

### 6. Register Map Boundary Conditions

| Feature | Address | Sequence | Status |
|---|---|---|---|
| First valid register (0x00) | 0x00 | `axi4l_normal_rw_seq` | _[PASS/FAIL]_ |
| Last R/W register (0x24) | 0x24 | `axi4l_normal_rw_seq` | _[PASS/FAIL]_ |
| First RO register (0x28) | 0x28 | `axi4l_ro_test_seq` | _[PASS/FAIL]_ |
| Last RO register (0x30) | 0x30 | `axi4l_ro_test_seq` | _[PASS/FAIL]_ |
| First WO register (0x34) | 0x34 | `axi4l_wo_test_seq` | _[PASS/FAIL]_ |
| Last WO register (0x38) | 0x38 | `axi4l_wo_test_seq` | _[PASS/FAIL]_ |
| Reserved register (0x3C) | 0x3C | `axi4l_normal_rw_seq` | _[PASS/FAIL]_ |
| First invalid address (0x40) | 0x40 | `axi4l_decerr_seq` | _[PASS/FAIL]_ |

---

## Code Coverage Gaps

| Gap Area | Current % | Root Cause | Plan |
|---|---|---|---|
| _[e.g. unreachable RTL state]_ | _[x%]_ | _[e.g. W_BOTH→W_DATA path not exercised]_ | _[add sequence]_ |
| Overall | 85.54% | — | Target: 90%+ |

---

## Regression Test List

| Test Name | Sequence | Transactions | Expected Result |
|---|---|---|---|
| `axi4l_write_test` | `axi4l_write_seq` | 1000 | All PASS |
| `axi4l_read_test` | `axi4l_read_seq` | 1000 | All PASS |
| `axi4l_normal_rw_test` | `axi4l_normal_rw_seq` | 500 | All PASS |
| `axi4l_ro_test` | `axi4l_ro_test_seq` | 300 | SLVERR on writes |
| `axi4l_wo_test` | `axi4l_wo_test_seq` | 300 | SLVERR on reads |
| `axi4l_decerr_test` | `axi4l_decerr_seq` | 200 | DECERR on all |
| `axi4l_unaligned_test` | `axi4l_unaligned_seq` | 200 | SLVERR on all |
| `axi4l_concurrent_test` | `axi4l_concurrent_seq` | 5000 | All PASS |
| `axi4l_fully_rand_test` | `axi4l_fully_rand` | 5000 | All PASS |
| `axi4l_write_bug_test` | `axi4l_write_bug_seq` | 20 | Bug reproduction |

---

## Known Limitations / Future Work

- Reset sequence not yet implemented — reset behavior verification is incomplete (tracked as coverage gap)
- Code coverage target 90% not yet achieved (currently 85.54%) — additional sequences needed to hit unreachable RTL paths
- Byte-enable (WSTRB) partial-write read-back verification can be strengthened with dedicated directed sequence
- No back-pressure stress sequence (READY deasserted mid-transaction) — could add to increase handshake coverage
