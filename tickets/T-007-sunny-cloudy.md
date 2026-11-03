---
id: T-007
title: Extend sunny/cloudy comparison to Phase 3
status: done
depends_on: [T-004]
phase: 3
---

# T-007 — Extend sunny/cloudy comparison to Phase 3

## Goal

Include the degradation-aware controller in the existing sunny-versus-cloudy
comparison so all four controllers are evaluated on both PV profiles.

## Files

- `Matlab/Comparison/prepare_cloudy_comparison.m`
- `Matlab/Comparison/plot_comparison.m`

## Changes

### `prepare_cloudy_comparison`

- Add `phase3` to `energy_summary` using the same fields as the other phases.
- Add Phase 3 to `print_costs` and `print_energy`.
- Store the alpha used on the result struct for provenance.

### `plot_comparison`

- Cost bars: four series
  `Baseline`, `Heuristic`, `LP naive`, `LP aware`.
- Daily details: four panels per scenario instead of three.
- Adjust figure height/position so four panels remain readable.
- Keep the existing colours and legend conventions.
- Label that Phase 2 uses the legacy degradation model and Phase 3 uses the
  DoD-aware model, so the degradation series are not read as directly
  comparable.

`plot_ems_comparison.m` is already phase-agnostic; reuse it rather than
duplicating its logic.

## Acceptance criteria

- [ ] `run_comparison` completes for both sunny and cloudy.
- [ ] Both scenarios contain `phase3`.
- [ ] Cost bars show four phases for daily, monthly, and grid cost.
- [ ] Daily-detail figures show four panels and correct titles.
- [ ] Phase 3 validation passes in both scenarios.
- [ ] No existing phase is dropped from the output.

## Verification

```matlab
cd Matlab
startup
results = run_comparison();
results.sunny.phase3.validation.all_checks_passed
results.cloudy.phase3.validation.all_checks_passed
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_phase3` (OVERALL PASS).
