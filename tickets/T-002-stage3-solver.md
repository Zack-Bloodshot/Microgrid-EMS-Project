---
id: T-002
title: Implement degradation-aware LP solver
status: done
depends_on: [T-001]
stage: 3
---

# T-002 — Implement degradation-aware LP solver

## Goal

Add the Stage 3 controller: the Stage 2 LP plus the DoD-aware linear throughput
penalty and a terminal-SOC lower bound. Build Stage 3's own constraints; do not
refactor Stage 2.

## Files

- `Matlab/Stage3/lp_degradation_aware_ems.m` (new)

## Interface

```matlab
function [P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, ...
          grid_cost, deg_cost, objective_value] = ...
    lp_degradation_aware_ems(P_pv, P_load, tariff, params, alpha)
```

- `alpha` defaults to `1` when omitted.
- Output trajectory order must match `lp_naive_ems.m` so validation and
  plotting code can be reused.

## Objective

```
f(imp) =  C_import * dt
f(exp) = -C_export * dt
f(ch)  =  alpha * c_deg * dt
f(dis) =  alpha * c_deg * dt
f(curt)=  0

c_deg  = params.Cost_replacement / ...
         (params.N_cycles_rated * 2 * params.E_B * params.DoD_rated)
```

`C_import` and `C_export` must come from `build_lp_price_vectors`.
Do not use `params.A_cycle` here; that is the frozen Stage 2 field.

## Constraints

- Build the power-balance, SOC-recursion, SOC-bound, and variable-bound rows
  locally in this function (or in a Stage 3-local helper). Do not modify
  `lp_naive_ems.m`.
- Terminal row: `sum_k (eta_ch*P_ch(k) - P_dis(k)/eta_dis) >= 0`.
- Decision vector order:
  `[P_gimp(1:N); P_gexp(1:N); P_ch(1:N); P_dis(1:N); P_curt(1:N)]`.
- Solve with `linprog`, `Display = 'none'`.
- Error with `lp_degradation_aware_ems:solverFailed` if `exitflag ~= 1`.
- Reconstruct `SOC` from the dispatch; do not treat it as a decision variable.
- Compute `grid_cost` with `calculate_costs` and `deg_cost` with
  `battery_degradation_dod`. Assert both match any internal recomputation.
- Set `objective_value` to the solver objective value; do not report it as a
  physical cost.

## Acceptance criteria

- [ ] `alpha = 0` on the sunny day matches Stage 2's grid cost within `1e-6`.
- [ ] `alpha = 0` dispatch matches Stage 2's dispatch within tolerance.
- [ ] `alpha = 1` satisfies `SOC(end) >= params.SOC0 - 1e-9`.
- [ ] `SOC` is `1 x N+1`; all power vectors are `1 x N` and nonnegative.
- [ ] No simultaneous charge/discharge above `params.bound_tol`.
- [ ] `deg_cost` equals `battery_degradation_dod(...)`, not the legacy Stage 2
      value.
- [ ] Solver failure raises the named error.

## Verification

```matlab
cd Matlab
startup
params  = system_params();
tariff  = tariff_params();
[P_pv, ~]   = generate_pv_profile(params);
[P_load, ~] = generate_load_profile(params);

[~, ~, ~, ~, ~, ~, g0] = ...
    lp_degradation_aware_ems(P_pv, P_load, tariff, params, 0);
[~, ~, ~, ~, ~, ~, g2] = lp_naive_ems(P_pv, P_load, tariff, params);
assert(abs(g0 - g2) < 1e-6)
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_stage3` (OVERALL PASS).
