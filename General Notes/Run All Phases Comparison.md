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
| **Phase 0** | Baseline (`rule_based_ems_p0`) | No | No storage — direct PV self-consumption, export surplus, import deficit | N/A (no battery) |
| **Phase 1** | Heuristic (`rule_based_ems_p1`) | Yes | Greedy rule-based: charge from PV surplus, discharge on deficit | Post-hoc only |
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
- ToD tariff multipliers (0.8× solar, 1.0× normal, 1.2× peak)
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
  ├── Phase 0: rule_based_ems_p0()  → baseline dispatch
  │     └── validate_power_balance_p0()
  │     └── calculate_costs()
  │
  ├── Phase 1: rule_based_ems_p1()  → heuristic dispatch
  │     └── validate_power_balance_p1()
  │     └── calculate_costs()
  │     └── battery_degradation()  → post-hoc EFC, DoD, LifeCycles
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
- **Degradation cross-check** — `battery_degradation` is called inside `lp_naive_ems` and again in `simulate_day`, asserted equal
- **Monthly = 30 × daily** — the simulated day is treated as a representative billing day. This is an extrapolation, not a simulated month.

---

## Results (Sunny Day)

All figures below are produced by `run_all_phases()` and are the actual
solver output — no value is scaled, tuned, or overwritten after the run.

| Phase | Grid Cost/day | Degradation/day | Total/day | Total/month | EFC |
|-------|--------------|-----------------|-----------|-------------|-----|
| Phase 0 (Baseline) | Rs 50.54 | Rs 0.00 | Rs 50.54 | Rs 1516.10 | 0.000 |
| Phase 1 (Heuristic) | Rs 28.97 | Rs 34.71 | Rs 63.69 | Rs 1910.55 | 0.801 |
| Phase 2 (LP) | Rs 24.69 | Rs 34.71 | Rs 59.40 | Rs 1781.94 | 0.801 |

**Savings vs. the no-battery baseline:**

| Comparison | Daily saving | Reduction |
|------------|--------------|-----------|
| Baseline → Heuristic | Rs 21.57 | **42.7%** |
| Baseline → LP | Rs 25.85 | **51.2%** |
| Heuristic → LP (grid cost) | Rs 4.29 | **14.8%** |

> **Note:** Phase 1 and Phase 2 both accrue post-hoc degradation cost —
> on this day they cycle identically (EFC 0.801 each), so both carry
> Rs 34.71/day. Phase 0 has no battery, so its degradation cost is
> genuinely zero. All costs are unscaled APDCL tariff values; no billing
> calibration factor is applied.
>
> **Note:** on total cost the battery is *more expensive than no battery*
> (Rs 59.40 vs Rs 50.54/day), because degradation against Rs 130,000
> CAPEX exceeds the electricity it saves. See [[Defensibility Analysis]] §6.

### Energy Flows

| Phase | Import | Export | Consumed |
|-------|--------|--------|----------|
| Phase 0 | 13.03 kWh | 11.33 kWh | 16.98 kWh |
| Phase 1 | 5.43 kWh | 2.91 kWh | 16.98 kWh |
| Phase 2 | 5.43 kWh | 2.91 kWh | 16.98 kWh |

> **Note:** Phase 1 and Phase 2 move *identical* energy on this day, yet
> the LP costs Rs 4.38 less. The saving is not from using less grid
> energy — it is from **when** that energy is bought. The LP shifts
> import out of the 1.2× peak window into cheaper hours, which is exactly
> the ToD arbitrage the battery exists to capture. The heuristic
> discharges the moment a deficit appears, wherever in the day that is.

---

## Why This Comparison Matters

### 1. It Quantifies the Battery's Value

The jump from Phase 0 to Phase 1 shows what a simple rule-based battery saves. The jump from Phase 1 to Phase 2 shows what optimal control adds on top. Together they answer: *"Is a battery worth it, and is the extra complexity of optimization worth it?"*

### 2. It Exposes the Greedy Heuristic's Weakness

The heuristic discharges the battery the instant a deficit appears, with
no knowledge of the tariff clock. The LP holds charge back and releases
it during the 1.2× peak window. On this day both end up moving the same
5.43 kWh of import, but the LP places it at cheaper times and saves
Rs 4.38/day (14.8%) doing so.

Because the two controllers cycle the battery equally (EFC 0.801 each),
the entire gap is attributable to dispatch *timing* — which is the cleanest
possible demonstration that the optimisation is doing real work rather
than merely cycling harder.

### 3. It Sets Up Phase 3

Phase 2 is "naive" — it ignores degradation in the objective. The post-hoc degradation cost (EFC, DoD, LifeCycles) is computed but not penalized. This creates the narrative tension for Phase 3: *"The LP saves the most on grid cost, but at what battery health cost?"*

### 4. It Validates the Pipeline

The cross-checks (grid cost computed twice, degradation computed twice, power balance validation) ensure that the three phases are internally consistent and comparable.

---

## The Cost Calculation

The `calculate_costs()` function applies the full APDCL tariff:

1. **Slab allocation** — imported energy is assigned chronologically to monthly slabs (0–300 kWh @ Rs 6.75, 300–500 @ Rs 6.95, 500+ @ Rs 7.74)
2. **ToD multipliers** — each timestep's slab rate is multiplied by the ToD factor (0.8× solar, 1.0× normal, 1.2× peak)
3. **Export compensation** — exported energy is credited Rs 4.00/kWh
4. **Fixed charge** — Rs 70/month ÷ 30 = Rs 2.33/day

No billing calibration factor is applied. Note that at this daily horizon
(~13 kWh import) all energy falls inside the first monthly slab, so the
300 kWh / 500 kWh boundaries are never reached — see the limitations
section in [[System Parameters & Tariff]].

---

## Relationship to Other Analyses

- **[[Cloudy vs Sunny Comparison]]** — takes the same three phases and runs them on two different PV profiles (sunny vs cloudy) to isolate the weather effect
- **[[README]]** — full project architecture including Phases 3–6 which build on this comparison
- **[[Objectives and Benefits]]** — the practical value proposition that these savings translate into

---

## Files Involved

- `Matlab/run_all_phases.m` — orchestration script
- `Matlab/simulate_day.m` — shared pipeline; single source of truth for running all controllers
- `Matlab/Phase0/rule_based_ems_p0.m` — baseline controller
- `Matlab/Phase1/rule_based_ems_p1.m` — heuristic controller
- `Matlab/Phase2/lp_naive_ems.m` — LP controller
- `Matlab/Phase2/battery_degradation.m` — post-hoc degradation model
- `Matlab/tariff_params.m` — APDCL tariff data
- `Matlab/calculate_costs.m` — cost calculation with slab + ToD rates
- `Matlab/system_params.m` — shared system parameters
- `Matlab/generate_pv_profile.m` — PV profile generator
- `Matlab/generate_load_profile.m` — load profile generator
