---
title: Structural Reform Plan
date: 2026-10-05
tags:
  - project
  - matlab
  - refactoring
  - ems
status: active
---

# Structural Reform Plan

> [!info] Project
> **Design & Modelling of a Cost-Optimized EMS for a Grid-Tied PV Microgrid**
> 
> Author: Abhijit — B.Tech Electrical Engineering, Assam Engineering College
> 
> Scope: Restructure for clarity and modularity. No logic/value changes.

---

## Goals

- Eliminate duplicated simulation logic across the project
- Standardize naming conventions (files, folders, functions)
- Consolidate the Cloudy Day comparison into a clean, reusable structure
- Add project hygiene (`.gitignore`, `startup.m`)
- Keep all current values and logic intact — this is purely structural

---

## Current Issues

> [!warning] Key Problems
> 1. **Duplicated simulation pipeline** — `run_all_phases.m` and `prepare_cloudy_comparison.m` contain near-identical logic
> 2. **Inconsistent naming** — `rule_based_ems` vs `rule_based_ems1`, spaces in folder names
> 3. **Hidden dependency** — `calculate_costs.m` calls `tariff_params()` internally
> 4. **Duplicated ToD logic** — `build_tod_multiplier()` exists in two places
> 5. **Scattered plotting** — Cloudy Day folder has 3 overlapping plot functions
> 6. **No project hygiene** — no `.gitignore`, no `startup.m`

---

## Proposed Final Structure

```
Matlab/
├── startup.m                    # NEW: adds all folders to path
├── system_params.m              # Cleaned formatting, same values
├── tariff_params.m              # Unchanged
├── generate_pv_profile.m
├── generate_load_profile.m
├── calculate_costs.m            # Refactored: takes tariff as argument
├── get_tod_multiplier.m         # NEW: shared ToD logic
├── simulate_day.m               # NEW: single simulation pipeline
├── run_all_phases.m             # Refactored to use simulate_day
├── Phase0/                      # Renamed (no space)
│   ├── rule_based_ems_p0.m      # Renamed
│   ├── main_phase0.m
│   ├── validate_power_balance_p0.m  # Renamed
│   └── Phase 0 (Implementation).md
├── Phase1/
│   ├── rule_based_ems_p1.m      # Renamed
│   ├── main_phase1.m
│   ├── validate_power_balance_p1.m  # Renamed
│   └── Phase 1 (Implementation).md
├── Phase2/
│   ├── lp_naive_ems.m           # Unchanged (no split for now)
│   ├── build_lp_price_vectors.m # Refactored to use get_tod_multiplier
│   ├── battery_degradation.m
│   ├── main_phase2.m
│   ├── validate_lp_solution.m
│   └── phase_2_implementation.md
└── Comparison/                  # Renamed from "Cloudy Day"
    ├── run_comparison.m
    ├── prepare_comparison.m     # Refactored to use simulate_day
    └── plot_comparison.m        # NEW: consolidated plotting
```

---

## Execution Steps

> [!tip] Recommended Order
> Each step builds on the previous one. Follow in sequence.

### Step 1 — Extract `simulate_day.m`

- Create `Matlab/simulate_day.m` — single function that takes `(P_pv, P_load, params, tariff)` and returns structured results for all 3 phases
- Refactor `run_all_phases.m` to call it
- Refactor `prepare_cloudy_comparison.m` to call it
- This becomes the single source of truth for "run all controllers on a given profile"

### Step 2 — Clean `system_params.m` Formatting

- Remove excessive blank lines (~25 consecutive)
- Keep all values as-is (`cloudy_target_daily_cost`, `heuristic_SOC_min`, etc.)

### Step 3 — Rename Files & Folders

| Current | Proposed |
|---------|----------|
| `Phase 0/` | `Phase0/` |
| `Phase 1/` | `Phase1/` |
| `Phase 2/` | `Phase2/` |
| `Cloudy Day/` | `Comparison/` |
| `rule_based_ems.m` | `rule_based_ems_p0.m` |
| `rule_based_ems1.m` | `rule_based_ems_p1.m` |
| `validate_power_balance.m` | `validate_power_balance_p0.m` |
| `validate_power_balance1.m` | `validate_power_balance_p1.m` |

### Step 4 — Fix `calculate_costs.m` Hidden Dependency

- Change signature from `calculate_costs(grid_power, tod_index)` to `calculate_costs(grid_power, tod_index, tariff)`
- Remove internal call to `tariff_params()`
- Update all callers to pass the tariff struct

### Step 5 — Deduplicate ToD Multiplier Logic

- Create `get_tod_multiplier(tariff)` in root `Matlab/` folder
- Update `calculate_costs.m` to call it
- Update `build_lp_price_vectors.m` to call it

### Step 6 — Consolidate Cloudy Day → Comparison

- Rename folder from `Cloudy Day/` to `Comparison/`
- Refactor `prepare_comparison.m` to use `simulate_day.m`
- Consolidate 3 separate plot functions into `plot_comparison.m`
- Keep `apply_cloudy_cost_targets()` and all existing logic as-is for now

### Step 7 — Add `.gitignore`

```gitignore
*.asv
*.fig
*.mlapp
*.slx
*.mdl
*.mat
!reference_data/*.mat
```

### Step 8 — Add `startup.m`

- Create `startup.m` in root `Matlab/` folder
- Adds all subfolders to MATLAB path
- Users run `startup` once before working

---

## Deferred (For Later)

> [!note] Not in Scope Right Now
> - Removing `apply_cloudy_cost_targets()` and magic numbers
> - Breaking up `lp_naive_ems.m` into smaller functions
> - Reconciling documentation parameter values with code
> - Adding unit tests
> - Removing `billing_scale` from `tariff_params.m`

---

## Related

- [[System Parameters & Tariff]]
- [[Run All Phases Comparison]]
- [[Cloudy vs Sunny Comparison]]
- [[Untitled]]
