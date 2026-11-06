---
id: T-005
title: Add main_stage3 driver and plots
status: done
depends_on: [T-004]
stage: 3
---

# T-005 — Add `main_stage3` driver and plots

## Goal

Provide the same standalone, presentation-friendly entry point for Stage 3
that `main_stage0`, `main_stage1`, and `main_stage2` provide for their stages.

## Files

- `Matlab/Stage3/main_stage3.m` (new)

## Tasks

- Add `Matlab`, `Matlab/Stage2`, and `Matlab/Stage3` to the path (the driver
  uses `calculate_costs`, `calaculate` helpers, and Stage 3's own degradation
  and validation functions).
- Load `system_params` and `tariff_params`.
- Generate sunny PV/load profiles.
- Set a clearly named `alpha` near the top, default `1`.
- Solve, validate with `validate_stage3_solution`, and compute degradation
  metrics with `battery_degradation_dod`.
- Plot in one figure:
  1. PV generation vs load.
  2. Dispatch (`P_ch`, `-P_dis`, `P_gimp`, `-P_gexp`).
  3. SOC with `SOC_min`, `SOC_max`, and a terminal-SOC marker.
  4. PV curtailment.
  5. Per-timestep DoD (diagnostic) or a cost-component bar.
- Print a summary: alpha, grid cost, degradation cost, total cost, EFC,
  final SOC, solver objective value, and degradation model label.
- Warn if validation fails, matching the style of the other `main_stageN`
  scripts.

## Acceptance criteria

- [ ] `main_stage3` runs from `Matlab/` with no manual path setup.
- [ ] All five panels render and are labelled.
- [ ] Summary prints costs and EFC with units and names the DoD-aware model.
- [ ] Validation status is printed and visible.
- [ ] Script works at `alpha = 0` and `alpha = 1`.
- [ ] No Stage 2 file is modified.

## Verification

```matlab
cd Matlab
startup
main_stage3
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_stage3` (OVERALL PASS).
