---
id: T-008
title: End-to-end verification script
status: done
depends_on: [T-001, T-002, T-003, T-004, T-005, T-006, T-007]
stage: 3
---

# T-008 — End-to-end verification script

## Goal

Add one repeatable command that proves Stage 3 is correct and did not regress
Stage 2. The repo has no MATLAB unit-test framework, so this is a plain
function with hard assertions and a printed check table.

## Files

- `Matlab/Stage3/verify_stage3.m` (new)

## Checks

1. **Stage 2 regression** — sunny grid cost, degradation cost, and EFC match
   the current legacy values `Rs 24.6857`, `Rs 20.83`, and `0.801` within a
   stated tolerance. If this fails, Stage 2 was accidentally changed.
2. **Stage 3 degradation model** — `battery_degradation_dod` reproduces
   `c_deg = 1.6250` Rs/kWh, `Rs 26.00`/rated cycle, `Rs 32.50`/EFC.
3. **Alpha-zero equivalence** — Stage 3 at `alpha = 0` matches Stage 2 **grid
   cost** within `1e-6`. Do **not** compare degradation: Stage 2 uses the
   legacy model and is expected to differ.
4. **Terminal SOC** — every Stage 3 run has `SOC(end) >= SOC0 - 1e-9`.
5. **Power balance** — max residual below `params.residual_tol`.
6. **Operating bounds** — SOC, charge/discharge, import/export, and
   curtailment checks all pass.
7. **No simultaneous cycling** — no timestep has both `P_ch` and `P_dis`
   above `params.bound_tol`.
8. **Cloudy case** — Stage 3 solves and validates on `cloudy_profile_1`.
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

- [x] `verify_stage3` runs from `Matlab/` with `startup` only.
- [x] Prints every check above.
- [x] Ends with `OVERALL: PASS` on the current code.
- [x] Deliberately breaking one check causes a named failure.
- [x] No generated files are required for it to run.
- [x] Stage 2 degradation is checked against `Rs 20.83`, not the Stage 3 value.

## Verification

```matlab
cd Matlab
startup
verify_stage3
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_stage3` (OVERALL PASS).
