---
id: T-001
title: Add DoD-aware degradation model
status: done
depends_on: []
stage: 3
---

# T-001 — Add DoD-aware degradation model

## Goal

Add a Stage 3 degradation model that prices battery wear at the design depth of
discharge and the rated cycle life, without touching the Stage 2 model or
results.

## Files

- `Matlab/system_params.m` (additive fields only)
- `Matlab/Stage3/battery_degradation_dod.m` (new)

Do **not** modify `Matlab/Stage2/battery_degradation.m`.

## Model

```
DoD_rated       = SOC_max - SOC_min = 0.90 - 0.10 = 0.80
N_cycles_rated  = 5000
E_cycle_rated   = 2 * E_B * DoD_rated = 16 kWh/rated cycle
c_deg           = Cost_replacement / (N_cycles_rated * E_cycle_rated)
                = 130000 / (5000 * 16)
                = Rs 1.6250 per kWh throughput
                = Rs 26.00 per rated 80%-DoD cycle
                = Rs 32.50 per equivalent full cycle
C_deg           = c_deg * sum_k (P_ch(k) + P_dis(k)) * dt
```

`DoD` and `LifeCycles` per timestep are retained as diagnostics only and must
not price wear.

## Interface

```matlab
function [deg_cost, EFC, DoD, LifeCycles] = ...
    battery_degradation_dod(P_ch, P_dis, params)
```

- `params.DoD_rated` is derived from `SOC_max - SOC_min`, not hard-coded.
- `params.N_cycles_rated = 5000`.
- Legacy `params.A_cycle = 5000` and `params.b_cycle = 1.3` stay in
  `system_params.m` because Stage 2 still reads them.

## Tasks

- Add `DoD_rated` and `N_cycles_rated` to `system_params.m` without removing
  the legacy fields.
- Implement `battery_degradation_dod.m` with a function header matching the
  existing Stage 2 style.
- Document that the per-timestep DoD is a 15-minute slice, not a full cycle.
- Document that Stage 2 remains on the legacy model.

## Acceptance criteria

- [x] `battery_degradation_dod` returns `c_deg = 1.6250` Rs/kWh throughput.
- [x] One rated 80%-DoD cycle costs Rs 26.00; one EFC costs Rs 32.50.
- [x] `DoD_rated` equals `params.SOC_max - params.SOC_min` (0.80).
- [x] `battery_degradation.m` API is unchanged (its cycle-life parameter is now
  5000).
- [x] Function returns `1 x N` `DoD` and `LifeCycles` diagnostics.

## Verification

```matlab
cd Matlab
startup
params = system_params();
P_ch  = zeros(1, 96);
P_dis = zeros(1, 96);
P_dis(1:4) = 5;               % 5 kW for 1 h = 5 kWh throughput
[cost, EFC, DoD, LC] = battery_degradation_dod(P_ch, P_dis, params);
assert(abs(params.DoD_rated - 0.80) < 1e-12);
assert(abs(cost - 1.6250*5) < 1e-3);
assert(abs(EFC - 5/20) < 1e-12);
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_stage3` (OVERALL PASS).
