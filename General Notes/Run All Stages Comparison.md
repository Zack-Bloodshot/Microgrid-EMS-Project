---
title: All-Stage EMS Comparison (run_all_stages.m)
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

# All-Stage EMS Comparison (`run_all_stages.m`)

## What This Does

`run_all_stages.m` is the **single-entry orchestration script** that runs all four EMS controller stages on the same PV/load profiles and produces a unified cost comparison. It replaces the need to run `main_stage0.m`, `main_stage1.m`, `main_stage2.m`, and `main_stage3.m` separately.

---

## The Four Stages

| Stage | Controller | Battery? | Objective | Degradation |
|-------|-----------|----------|-----------|-------------|
| **Stage 0** | Baseline (`rule_based_ems_p0`) | No | No storage — direct PV self-consumption, export surplus, import deficit | N/A (no battery) |
| **Stage 1** | Heuristic (`rule_based_ems_p1`) | Yes | Greedy rule-based: charge from PV surplus, discharge on deficit | Post-hoc, shared model |
| **Stage 2** | LP naive (`lp_naive_ems`) | Yes | Grid-cost-minimizing linear program (full foresight) | Post-hoc, shared model |
| **Stage 3** | LP aware (`lp_degradation_aware_ems`) | Yes | Grid + wear cost, terminal SOC ≥ SOC0 | In the objective |

### Stage 0 — Baseline (No Battery)

The simplest possible controller:
- PV serves load directly
- Surplus PV → export to grid (capped at `P_grid_exp_max`)
- Deficit → import from grid (capped at `P_grid_imp_max`)
- Any surplus that can't be exported is curtailed

This is the "do nothing" reference point — what your bill looks like with solar but no battery.

### Stage 1 — Heuristic (Greedy Battery)

A rule-based controller with two modes:
- **Surplus** (`P_pv ≥ P_load`): charge battery → export remainder → curtail rest
- **Deficit** (`P_pv < P_load`): discharge battery → import remainder

No foresight — it only reacts to the current timestep. The battery only charges from PV, never from the grid.

### Stage 2 — LP (Optimal Battery)

A linear program that minimizes total grid cost across the full 24-hour horizon with perfect knowledge of:
- PV generation profile
- Load profile
- ToD tariff multipliers (0.8× solar, 1.0× normal, 1.2× peak)
- Slab rates

The LP can charge the battery from the grid during cheap hours and discharge during expensive ones — something the heuristic cannot do. Degradation cost is computed **post-hoc** (not in the objective), which is the "naive" approach that Stage 3 improves upon.

### Stage 3 — Degradation-Aware LP

Same decision vector and constraints as Stage 2, plus a terminal SOC lower
bound and a wear term `alpha * c_deg * (P_ch + P_dis) * dt` in the objective.
At `alpha = 1`, wear is priced at its modelled cost. Every stage reports wear
with the same `battery_degradation.m` model, so the totals are directly
comparable.

---

## How It Works (Code Pipeline)

```
run_all_stages()
  ├── system_params()              → shared battery/PV/timing parameters
  ├── generate_pv_profile()        → 24h PV curve (sunny day)
  ├── generate_load_profile()      → 24h load curve
  │
  ├── Stage 0: rule_based_ems_p0()  → baseline dispatch
  │     └── validate_power_balance_p0()
  │     └── calculate_costs()
  │
  ├── Stage 1: rule_based_ems_p1()  → heuristic dispatch
  │     └── validate_power_balance_p1()
  │     └── calculate_costs()
  │     └── battery_degradation()  → post-hoc EFC, DoD, LifeCycles
  │
  ├── Stage 2: lp_naive_ems()      → LP optimal dispatch
  │     └── validate_lp_solution()
  │     └── battery_degradation()  → post-hoc EFC, DoD, LifeCycles
  │     └── calculate_costs()      → cross-check grid cost
  │
  ├── Stage 3: lp_degradation_aware_ems() → wear-aware dispatch
  │     └── validate_stage3_solution()
  │     └── battery_degradation()  → post-hoc cross-check
  │     └── calculate_costs()      → cross-check grid cost
  │
  ├── Console table                → grid/degradation/total per stage
  └── Stacked bar chart            → daily cost components + monthly bill
```

### Key Design Decisions

- **Same profiles for all stages** — only the controller changes, isolating the algorithmic effect
- **Cross-validation** — Stage 2 grid cost is computed twice (inside `lp_naive_ems` and again via `calculate_costs`) and asserted equal
- **Degradation cross-check** — `battery_degradation` is called inside `lp_naive_ems` and again in `simulate_day`, asserted equal
- **Monthly = 30 × daily** — the simulated day is treated as a representative billing day. This is an extrapolation, not a simulated month.

---

## Results (Sunny Day)

All figures below are produced by `run_all_stages()` and are the actual
solver output — no value is scaled, tuned, or overwritten after the run.

| Stage | Grid Cost/day | Degradation/day | Total/day | Total/month | EFC |
|-------|--------------|-----------------|-----------|-------------|-----|
| Stage 0 (Baseline) | Rs 50.54 | Rs 0.00 | Rs 50.54 | Rs 1516.10 | 0.000 |
| Stage 1 (Heuristic) | Rs 28.97 | Rs 26.03 | Rs 55.01 | Rs 1650.21 | 0.801 |
| Stage 2 (LP naive) | Rs 24.69 | Rs 26.03 | Rs 50.72 | Rs 1521.60 | 0.801 |
| Stage 3 (LP aware) | Rs 26.88 | Rs 22.10 | **Rs 48.97** | **Rs 1469.21** | 0.680 |

**Savings vs. the no-battery baseline:**

| Comparison | Daily saving | Reduction |
|------------|--------------|-----------|
| Baseline → Heuristic (grid) | Rs 21.57 | **42.7%** |
| Baseline → LP naive (grid) | Rs 25.85 | **51.2%** |
| Heuristic → LP naive (grid) | Rs 4.29 | **14.8%** |
| Baseline → LP aware (total) | Rs 1.56 | **3.1%** |
| LP naive → LP aware (total) | Rs 1.75 | **3.4%** |

> **Note:** Stage 1 and Stage 2 both accrue post-hoc degradation cost —
> on this day they cycle identically (EFC 0.801 each), so both carry
> Rs 26.03/day. Stage 0 has no battery, so its degradation cost is
> genuinely zero. All costs are unscaled APDCL tariff values; no billing
> calibration factor is applied.
>
> **Note:** under the shared 80%-DoD, 5000-cycle model the naive battery
> dispatch does **not** pay for itself (Rs 50.72 vs Rs 50.54/day), and the
> heuristic is worse still (Rs 55.01). Only the degradation-aware Stage 3
> controller beats doing nothing (Rs 48.97). See
> [[Defensibility Analysis]] §6 and [[Stage 3 Results]].

### Energy Flows

| Stage | Import | Export | Consumed |
|-------|--------|--------|----------|
| Stage 0 | 13.03 kWh | 11.33 kWh | 16.98 kWh |
| Stage 1 | 5.43 kWh | 2.91 kWh | 16.98 kWh |
| Stage 2 | 5.43 kWh | 2.91 kWh | 16.98 kWh |
| Stage 3 | 6.58 kWh | 4.18 kWh | 16.98 kWh |

> **Note:** Stage 1 and Stage 2 move *identical* energy on this day, yet
> the LP costs Rs 4.29 less. The saving is not from using less grid
> energy — it is from **when** that energy is bought. The LP shifts
> import out of the 1.2× peak window into cheaper hours, which is exactly
> the ToD arbitrage the battery exists to capture. The heuristic
> discharges the moment a deficit appears, wherever in the day that is.

---

## Why This Comparison Matters

### 1. It Quantifies the Battery's Value

The jump from Stage 0 to Stage 1 shows what a simple rule-based battery saves. The jump from Stage 1 to Stage 2 shows what optimal control adds on top. Together they answer: *"Is a battery worth it, and is the extra complexity of optimization worth it?"*

### 2. It Exposes the Greedy Heuristic's Weakness

The heuristic discharges the battery the instant a deficit appears, with
no knowledge of the tariff clock. The LP holds charge back and releases
it during the 1.2× peak window. On this day both end up moving the same
5.43 kWh of import, but the LP places it at cheaper times and saves
Rs 4.29/day (14.8%) doing so.

Because the two controllers cycle the battery equally (EFC 0.801 each),
the entire gap is attributable to dispatch *timing* — which is the cleanest
possible demonstration that the optimisation is doing real work rather
than merely cycling harder.

### 3. It Sets Up Stage 3

Stage 2 is "naive" — it ignores degradation in the objective. The post-hoc degradation cost (EFC, DoD, LifeCycles) is computed but not penalized. This creates the narrative tension for Stage 3: *"The LP saves the most on grid cost, but at what battery health cost?"* Stage 3 answers it by cycling less (EFC 0.801 → 0.680) and landing Rs 1.75/day below Stage 2 on total cost.

### 4. It Validates the Pipeline

The cross-checks (grid cost computed twice, degradation computed twice, power balance validation) ensure that the four stages are internally consistent and comparable.

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

- **[[Cloudy vs Sunny Comparison]]** — takes the same four stages and runs them on two different PV profiles (sunny vs cloudy) to isolate the weather effect
- **[[README]]** — full project architecture including Stages 3–6 which build on this comparison
- **[[Objectives and Benefits]]** — the practical value proposition that these savings translate into

---

## Files Involved

- `Matlab/run_all_stages.m` — orchestration script
- `Matlab/simulate_day.m` — shared pipeline; single source of truth for running all controllers
- `Matlab/Stage0/rule_based_ems_p0.m` — baseline controller
- `Matlab/Stage1/rule_based_ems_p1.m` — heuristic controller
- `Matlab/Stage2/lp_naive_ems.m` — LP naive controller
- `Matlab/Stage3/lp_degradation_aware_ems.m` — degradation-aware LP controller
- `Matlab/battery_degradation.m` — shared degradation model
- `Matlab/tariff_params.m` — APDCL tariff data
- `Matlab/calculate_costs.m` — cost calculation with slab + ToD rates
- `Matlab/system_params.m` — shared system parameters
- `Matlab/generate_pv_profile.m` — PV profile generator
- `Matlab/generate_load_profile.m` — load profile generator
