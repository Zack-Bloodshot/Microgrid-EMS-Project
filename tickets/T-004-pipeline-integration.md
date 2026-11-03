---
id: T-004
title: Integrate Phase 3 into the shared pipeline
status: done
depends_on: [T-002, T-003]
phase: 3
---

# T-004 — Integrate Phase 3 into the shared pipeline

## Goal

Make Phase 3 a first-class result of `simulate_day` and include it in
`run_all_phases`.

## Files

- `Matlab/simulate_day.m`
- `Matlab/run_all_phases.m`

## Changes

### `simulate_day`

- Extend the signature to
  `simulate_day(P_pv, P_load, params, tariff, alpha)`.
- Default `alpha = 1` when the fifth argument is omitted.
- Run `lp_degradation_aware_ems` after Phase 2.
- Validate with `validate_phase3_solution`.
- Compute `battery_degradation_dod`; assert it matches the solver's `deg_cost`.
- Recompute grid cost with `calculate_costs`; assert it matches.
- Store `results.phase3` with the same field layout as `results.phase2`,
  plus `alpha` and `objective_value`.
- Keep Phase 2 on `battery_degradation`; do not re-price it.

### `run_all_phases`

- Add Phase 3 to the names, cost arrays, and EFC array.
- Print four rows.
- Include Phase 3 in the stacked daily-cost bar and monthly bar.
- Keep `alpha = 1` as the default comparison run; expose it as an optional
  function argument if that stays simple.
- Add a footnote or label clarifying that Phase 2 and Phase 3 use different
  degradation models.

## Acceptance criteria

- [x] `simulate_day` with four arguments still works and includes `phase3`.
- [x] `run_all_phases` prints four rows with Phase 3 `PASS`.
- [x] Phase 3 costs in the table equal `grid_cost + degradation_cost`.
- [x] Phase 1 and Phase 2 numbers reflect the current 5000-cycle legacy model,
      including Phase 2 degradation `Rs 20.83`.
- [x] Phase 3 row shows `EFC` and final SOC.
- [x] The output labels which degradation model each phase uses.

## Verification

```matlab
cd Matlab
startup
results = run_all_phases();
results.phase3.validation.all_checks_passed
results.phase3.SOC(end) >= results.params.SOC0
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_phase3` (OVERALL PASS).
