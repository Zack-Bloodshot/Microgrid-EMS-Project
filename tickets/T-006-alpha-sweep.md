---
id: T-006
title: Add alpha sweep and trade-off plot
status: done
depends_on: [T-002, T-004]
stage: 3
---

# T-006 — Add alpha sweep and trade-off plot

## Goal

Quantify the cost-versus-wear trade-off instead of reporting a single alpha,
and locate where the controller stops cycling the battery.

## Files

- `Matlab/Stage3/run_alpha_sweep.m` (new)
- `General Notes/assets/stage3-alpha-sweep.png` (generated, committed)

## Interface

```matlab
function sweep = run_alpha_sweep(alphas)
```

Default sweep:

```
[0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3, 5]
```

The interesting region is around `alpha = 1`, where normal-window arbitrage is
expected to drop out but peak-window cycling survives. Include `0` and `1`;
do not remove the low end.

## Data to record per alpha

- `alpha`
- `grid_cost`
- `deg_cost` (from `battery_degradation_dod`)
- `total_cost` (`grid_cost + deg_cost`, physical, not alpha-weighted)
- `EFC`
- `SOC_end`
- `P_curt` energy
- `objective_value`
- `validation.all_checks_passed`

## Plots

2x2 figure:

1. Grid cost vs alpha.
2. Degradation cost vs alpha.
3. Total physical cost vs alpha.
4. EFC vs alpha.

Save to `General Notes/assets/stage3-alpha-sweep.png` with
`print(..., '-dpng', '-r150')`.

## Knee definition

Define the knee reproducibly as:

> the smallest alpha at which `EFC <= 0.5 * EFC(alpha = 0)`.

Store it in `sweep.knee_alpha`; use `NaN` if no alpha qualifies. State the
definition in the printed summary and in the results note.

## Acceptance criteria

- [ ] Sweep includes `alpha = 0` and `alpha = 1`.
- [ ] Every point passes validation.
- [ ] Increasing alpha never increases EFC or degradation cost.
- [ ] Increasing alpha never decreases grid cost.
- [ ] `sweep.knee_alpha` is populated or explicitly `NaN` with a reason.
- [ ] PNG is written and non-empty.
- [ ] Printed table includes all recorded columns and the degradation model.

## Verification

```matlab
cd Matlab
startup
sweep = run_alpha_sweep();
sweep.knee_alpha
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_stage3` (OVERALL PASS).
