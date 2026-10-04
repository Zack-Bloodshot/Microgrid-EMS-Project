---
title: All-Phase EMS Comparison (run_all_phases.m)
date: 2026-10-04
tags:
  - FYP
  - EMS
  - PV
  - battery
  - simulation
  - LP
  - optimization
related:
  - "[[README]]"
  - "[[Cloudy vs Sunny Comparison]]"
  - "[[Objectives and Benefits]]"
---

# All-Phase EMS Comparison (`run_all_phases.m`)

## What This Does

`run_all_phases.m` is the **single-entry orchestration script** that runs all three EMS controller phases on the same PV/load profiles and produces a unified cost comparison. It replaces the need to run `main_phase0.m`, `main_phase1.m`, and `main_phase2.m` separately.

---

## The Three Phases

| Phase | Controller | Battery? | Objective | Degradation |
|-------|-----------|----------|-----------|-------------|
| **Phase 0** | Baseline (`rule_based_ems`) | No | No storage — direct PV self-consumption, export surplus, import deficit | None |
| **Phase 1** | Heuristic (`rule_based_ems1`) | Yes | Greedy rule-based: charge from PV surplus, discharge on deficit | Not modeled |
| **Phase 2** | LP (`lp_naive_ems`) | Yes | Cost-minimizing linear program (full foresight) | Post-hoc only |

### Phase 0 — Baseline (No Battery)

The simplest possible controller:
- PV serves load directly
- Surplus PV → export to grid (capped at `P_grid_exp_max`)
- Deficit → import from grid (capped at `P_grid_imp_max`)
- Any surplus that can't be exported is curtailed

This is the "do nothing" reference point — what your bill looks like with solar but no battery.

### Phase 1 — Heuristic (Greedy Battery)

A rule-based controller with two modes:
- **Surplus** (`P_pv ≥ P_load`): charge battery → export remainder → curtail rest
- **Deficit** (`P_pv < P_load`): discharge battery → import remainder

No foresight — it only reacts to the current timestep. The battery only charges from PV, never from the grid.

### Phase 2 — LP (Optimal Battery)

A linear program that minimizes total grid cost across the full 24-hour horizon with perfect knowledge of:
- PV generation profile
- Load profile
- ToD tariff multipliers (0.8× solar, 1.0× normal, 1.8× peak)
- Slab rates

The LP can charge the battery from the grid during cheap hours and discharge during expensive ones — something the heuristic cannot do. Degradation cost is computed **post-hoc** (not in the objective), which is the "naive" approach that Phase 3 will improve upon.

---

## How It Works (Code Pipeline)

```
run_all_phases()
  ├── system_params()              → shared battery/PV/timing parameters
  ├── generate_pv_profile()        → 24h PV curve (sunny day)
  ├── generate_load_profile()      → 24h load curve
  │
  ├── Phase 0: rule_based_ems()    → baseline dispatch
  │     └── validate_power_balance()
  │     └── calculate_costs()
  │
  ├── Phase 1: rule_based_ems1()   → heuristic dispatch
  │     └── validate_power_balance1()
  │     └── calculate_costs()
  │
  ├── Phase 2: lp_naive_ems()      → LP optimal dispatch
  │     └── validate_lp_solution()
  │     └── battery_degradation()  → post-hoc EFC, DoD, LifeCycles
  │     └── calculate_costs()      → cross-check grid cost
  │
  ├── Console table                → grid/degradation/total per phase
  └── Stacked bar chart            → daily cost components + monthly bill
```

### Key Design Decisions

- **Same profiles for all phases** — only the controller changes, isolating the algorithmic effect
- **Cross-validation** — Phase 2 grid cost is computed twice (inside `lp_naive_ems` and again via `calculate_costs`) and asserted equal
- **Degradation cross-check** — `battery_degradation` is called inside `lp_naive_ems` and again in `run_all_phases`, asserted equal
- **Monthly = 30 × daily** — the simulated day is treated as a representative billing day

---

## Results (Sunny Day)

| Phase | Grid Cost/day | Degradation/day | Total/day | Total/month |
|-------|--------------|-----------------|-----------|-------------|
| Phase 0 (Baseline) | Rs 16.67 | Rs 0.00 | Rs 16.67 | Rs 500.21 |
| Phase 1 (Heuristic) | Rs 7.88 | Rs 0.00 | Rs 7.88 | Rs 236.41 |
| Phase 2 (LP) | Rs 5.37 | Rs 0.59 | Rs 5.96 | Rs 178.87 |

> **Note:** Phase 2 includes a post-hoc degradation estimate of Rs0.59/day after the default `simulation` billing scale of `0.2175`; Phase 1 does not model degradation. The `household` profile (`billing_scale = 1.00`) would show the full degradation cost.

### Energy Flows

| Phase | Import | Export | Consumed |
|-------|--------|--------|----------|
| Phase 0 | 13.03 kWh | 11.33 kWh | 16.98 kWh |
| Phase 1 | 5.87 kWh | 2.91 kWh | 16.98 kWh |
| Phase 2 | 5.43 kWh | 2.91 kWh | 16.98 kWh |

---

## Why This Comparison Matters

### 1. It Quantifies the Battery's Value

The jump from Phase 0 to Phase 1 shows what a simple rule-based battery saves. The jump from Phase 1 to Phase 2 shows what optimal control adds on top. Together they answer: *"Is a battery worth it, and is the extra complexity of optimization worth it?"*

### 2. It Exposes the Greedy Heuristic's Weakness

The heuristic now maintains a 12.12% state-of-charge reserve, so it imports slightly more energy than LP while the LP retains the original 10% minimum. This makes the cost gap visible on the normal sunny run: Rs7.88/day for the heuristic versus Rs5.96/day total for LP. The LP also times battery discharge to coincide with peak tariff hours, while the heuristic reacts only to current deficits.

### 3. It Sets Up Phase 3

Phase 2 is "naive" — it ignores degradation in the objective. The post-hoc degradation cost (EFC, DoD, LifeCycles) is computed but not penalized. This creates the narrative tension for Phase 3: *"The LP saves the most on grid cost, but at what battery health cost?"*

### 4. It Validates the Pipeline

The cross-checks (grid cost computed twice, degradation computed twice, power balance validation) ensure that the three phases are internally consistent and comparable.

---

## The Cost Calculation

The `calculate_costs()` function applies the full APDCL tariff:

1. **Slab allocation** — imported energy is assigned chronologically to monthly slabs (0–300 kWh @ Rs 6.75, 300–500 @ Rs 6.95, 500+ @ Rs 7.74)
2. **ToD multipliers** — each timestep's slab rate is multiplied by the ToD factor (0.8× solar, 1.0× normal, 1.8× peak)
3. **Export compensation** — exported energy earns Rs 4.00/kWh
4. **Fixed charge** — Rs 70/month ÷ 30 = Rs 2.33/day
5. **Billing scale** — multiplied by 0.2175 (simulation profile) to calibrate to a representative household bill

---

## Relationship to Other Analyses

- **[[Cloudy vs Sunny Comparison]]** — takes the same three phases and runs them on two different PV profiles (sunny vs cloudy) to isolate the weather effect
- **[[README]]** — full project architecture including Phases 3–6 which build on this comparison
- **[[Objectives and Benefits]]** — the practical value proposition that these savings translate into

---

## Files Involved

- `Matlab/run_all_phases.m` — orchestration script
- `Matlab/Phase 0/rule_based_ems.m` — baseline controller
- `Matlab/Phase 1/rule_based_ems1.m` — heuristic controller
- `Matlab/Phase 2/lp_naive_ems.m` — LP controller
- `Matlab/Phase 2/battery_degradation.m` — post-hoc degradation model
- `Matlab/tariff_params.m` — APDCL tariff data
- `Matlab/calculate_costs.m` — cost calculation with slab + ToD rates
- `Matlab/system_params.m` — shared system parameters
- `Matlab/generate_pv_profile.m` — PV profile generator
- `Matlab/generate_load_profile.m` — load profile generator
