---
id: T-007
title: Extend sunny/cloudy comparison to Stage 3
status: done
depends_on: [T-004]
stage: 3
---

# T-007 — Extend sunny/cloudy comparison to Stage 3

## Goal

Include the degradation-aware controller in the existing sunny-versus-cloudy
comparison so all four controllers are evaluated on both PV profiles.

## Files

- `Matlab/Comparison/prepare_cloudy_comparison.m`
- `Matlab/Comparison/plot_comparison.m`

## Changes

### `prepare_cloudy_comparison`

- Add `stage3` to `energy_summary` using the same fields as the other stages.
- Add Stage 3 to `print_costs` and `print_energy`.
- Store the alpha used on the result struct for provenance.

### `plot_comparison`

- Cost bars: four series
  `Baseline`, `Heuristic`, `LP naive`, `LP aware`.
- Daily details: four panels per scenario instead of three.
- Adjust figure height/position so four panels remain readable.
- Keep the existing colours and legend conventions.
- Label that Stage 2 uses the legacy degradation model and Stage 3 uses the
  DoD-aware model, so the degradation series are not read as directly
  comparable.

`plot_ems_comparison.m` is already stage-agnostic; reuse it rather than
duplicating its logic.

## Acceptance criteria

- [ ] `run_comparison` completes for both sunny and cloudy.
- [ ] Both scenarios contain `stage3`.
- [ ] Cost bars show four stages for daily, monthly, and grid cost.
- [ ] Daily-detail figures show four panels and correct titles.
- [ ] Stage 3 validation passes in both scenarios.
- [ ] No existing stage is dropped from the output.

## Verification

```matlab
cd Matlab
startup
results = run_comparison();
results.sunny.stage3.validation.all_checks_passed
results.cloudy.stage3.validation.all_checks_passed
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_stage3` (OVERALL PASS).
