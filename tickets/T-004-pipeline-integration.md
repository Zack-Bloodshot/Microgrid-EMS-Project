---
id: T-004
title: Integrate Stage 3 into the shared pipeline
status: done
depends_on: [T-002, T-003]
stage: 3
---

# T-004 — Integrate Stage 3 into the shared pipeline

## Goal

Make Stage 3 a first-class result of `simulate_day` and include it in
`run_all_stages`.

## Files

- `Matlab/simulate_day.m`
- `Matlab/run_all_stages.m`

## Changes

### `simulate_day`

- Extend the signature to
  `simulate_day(P_pv, P_load, params, tariff, alpha)`.
- Default `alpha = 1` when the fifth argument is omitted.
- Run `lp_degradation_aware_ems` after Stage 2.
- Validate with `validate_stage3_solution`.
- Compute `battery_degradation_dod`; assert it matches the solver's `deg_cost`.
- Recompute grid cost with `calculate_costs`; assert it matches.
- Store `results.stage3` with the same field layout as `results.stage2`,
  plus `alpha` and `objective_value`.
- Keep Stage 2 on `battery_degradation`; do not re-price it.

### `run_all_stages`

- Add Stage 3 to the names, cost arrays, and EFC array.
- Print four rows.
- Include Stage 3 in the stacked daily-cost bar and monthly bar.
- Keep `alpha = 1` as the default comparison run; expose it as an optional
  function argument if that stays simple.
- Add a footnote or label clarifying that Stage 2 and Stage 3 use different
  degradation models.

## Acceptance criteria

- [x] `simulate_day` with four arguments still works and includes `stage3`.
- [x] `run_all_stages` prints four rows with Stage 3 `PASS`.
- [x] Stage 3 costs in the table equal `grid_cost + degradation_cost`.
- [x] Stage 1 and Stage 2 numbers reflect the current 5000-cycle legacy model,
      including Stage 2 degradation `Rs 20.83`.
- [x] Stage 3 row shows `EFC` and final SOC.
- [x] The output labels which degradation model each stage uses.

## Verification

```matlab
cd Matlab
startup
results = run_all_stages();
results.stage3.validation.all_checks_passed
results.stage3.SOC(end) >= results.params.SOC0
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_stage3` (OVERALL PASS).
