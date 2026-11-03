---
id: T-008
title: End-to-end verification script
status: done
depends_on: [T-001, T-002, T-003, T-004, T-005, T-006, T-007]
phase: 3
---

# T-008 — End-to-end verification script

## Goal

Add one repeatable command that proves Phase 3 is correct and did not regress
Phase 2. The repo has no MATLAB unit-test framework, so this is a plain
function with hard assertions and a printed check table.

## Files

- `Matlab/Phase3/verify_phase3.m` (new)

## Checks

1. **Phase 2 regression** — sunny grid cost, degradation cost, and EFC match
   the current legacy values `Rs 24.6857`, `Rs 20.83`, and `0.801` within a
   stated tolerance. If this fails, Phase 2 was accidentally changed.
2. **Phase 3 degradation model** — `battery_degradation_dod` reproduces
   `c_deg = 1.6250` Rs/kWh, `Rs 26.00`/rated cycle, `Rs 32.50`/EFC.
3. **Alpha-zero equivalence** — Phase 3 at `alpha = 0` matches Phase 2 **grid
   cost** within `1e-6`. Do **not** compare degradation: Phase 2 uses the
   legacy model and is expected to differ.
4. **Terminal SOC** — every Phase 3 run has `SOC(end) >= SOC0 - 1e-9`.
5. **Power balance** — max residual below `params.residual_tol`.
6. **Operating bounds** — SOC, charge/discharge, import/export, and
   curtailment checks all pass.
7. **No simultaneous cycling** — no timestep has both `P_ch` and `P_dis`
   above `params.bound_tol`.
8. **Cloudy case** — Phase 3 solves and validates on `cloudy_profile_1`.
9. **Sweep sanity** — degradation/EFC nonincreasing and grid cost
   nondecreasing across the sweep.
10. **Cost consistency** — stored `total_cost == grid_cost + degradation_cost`
    within `1e-9`, where `degradation_cost` comes from
    `battery_degradation_dod`.

## Output

Print a table of check name and `PASS`/`FAIL`, then:

```
OVERALL: PASS
```

On failure, identify the failed check and raise an error so CI-like use is
possible even without a test framework.

## Acceptance criteria

- [x] `verify_phase3` runs from `Matlab/` with `startup` only.
- [x] Prints every check above.
- [x] Ends with `OVERALL: PASS` on the current code.
- [x] Deliberately breaking one check causes a named failure.
- [x] No generated files are required for it to run.
- [x] Phase 2 degradation is checked against `Rs 20.83`, not the Phase 3 value.

## Verification

```matlab
cd Matlab
startup
verify_phase3
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_phase3` (OVERALL PASS).
