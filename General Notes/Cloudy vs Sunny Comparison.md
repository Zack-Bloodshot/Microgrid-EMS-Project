---
title: Cloudy vs Sunny Day EMS Comparison
date: 2026-10-04
tags:
  - FYP
  - EMS
  - PV
  - battery
  - simulation
related:
  - "[[README]]"
  - "[[Objectives and Benefits]]"
  - "[[Evidence]]"
---

# Cloudy vs Sunny Day EMS Comparison

## What This Does

This analysis runs the same four EMS controllers — **Baseline** (no battery), **Heuristic** (rule-based battery), **LP naive** (grid-cost-only LP), and **LP aware** (degradation-aware LP) — on two different PV days:

- **Sunny day:** 15.28 kWh of PV generation
- **Cloudy day:** 6.94 kWh of PV generation (roughly 45%)

The goal is to quantify how much a battery saves under each condition and *why* the savings differ.

---

## Why This Matters

### The Core Problem: Export vs Import Price Asymmetry

The APDCL tariff structure creates a fundamental arbitrage opportunity:

| Direction | Rate | What it means |
|-----------|------|---------------|
| **Export** (selling PV to grid) | Rs 4.00/kWh | You earn very little for surplus solar |
| **Import** (buying from grid) | Rs 5.40–8.10/kWh | You pay 1.4–2× more to buy it back |

Without a battery, excess PV is exported at Rs 4/kWh, and when the sun sets, you buy it back at Rs 5.40–8.10/kWh. **The battery breaks this cycle** by storing surplus PV locally instead of exporting it, then using it during peak hours instead of importing.

### Why Cloudy Days Are Different

On a sunny day, there's abundant excess PV to export — the battery has plenty to store. On a cloudy day, PV barely covers the load, so:

1. **Less export compensation** — the baseline's "free money" from exports shrinks
2. **More grid import needed** — the deficit is larger, especially during peak hours
3. **Battery value shifts** — instead of just storing surplus, the battery becomes critical for *peak shaving* (avoiding expensive peak-hour imports)

This is why the savings pattern changes: on sunny days the battery earns by *avoiding low export rates*, while on cloudy days it earns by *avoiding high import rates*.

---

## How It Works (Code Pipeline)

```
run_comparison()
  ├── prepare_cloudy_comparison()
  │     ├── generate_pv_profile()      → sunny PV curve
  │     ├── cloudy_profile_1()         → cloudy PV curve
  │     ├── generate_load_profile()    → load curve (same for both)
  │     ├── simulate_day() × 2         → runs all 4 controllers per scenario
  │     │     ├── rule_based_ems_p0()  → baseline (no battery)
  │     │     ├── rule_based_ems_p1()  → heuristic (greedy battery)
  │     │     ├── lp_naive_ems()       → LP naive (grid cost only)
  │     │     └── lp_degradation_aware_ems() → LP aware (wear priced)
  │     └── energy_summary()           → kWh consumed/import/export per case
  ├── plot_comparison()               → cost bars + 24h dispatch plots
  └── plot_ems_comparison()           → per-stage SOC / curtailment plots
```

### Key Design Decisions

- **Same load profile** for both scenarios — only PV changes, isolating the weather effect
- **Same initial SOC (0.10)** for both scenarios — fair comparison
- **Time step:** 15 minutes (96 samples/day)
- **Battery:** 10 kWh, 5 kW max charge/discharge, 95% round-trip efficiency

---

## Why Having a Battery Is Good

### 1. Arbitrage (Buy Low, Sell High)

The battery charges when electricity is cheap (solar hours at 0.8× tariff, or free PV surplus) and discharges when electricity is expensive (peak hours at 1.2× tariff). Every kWh shifted captures the price spread.

### 2. Self-Consumption Maximization

Without a battery, surplus PV is exported at Rs 4/kWh. With a battery, that same PV is stored and used later — effectively "selling" it at the import rate (Rs 5.40–8.10/kWh) instead of the export rate.

### 3. Peak Shaving

The load profile has an evening peak (19:30) that coincides with the 1.2× peak tariff multiplier. The battery discharges during this window, avoiding the most expensive grid power.

### 4. Reduced Grid Dependency

On a sunny day with the LP controller, grid import drops from 13.03 kWh to 5.43 kWh — a **58% reduction**. This insulates the consumer from tariff hikes and grid instability.

---

## Results Summary

All figures are direct `prepare_cloudy_comparison()` output. Nothing is
calibrated, scaled, or substituted after the run.

**Grid cost** is the electricity charge alone — the basis used by most
published EMS comparisons. **Total cost** adds battery degradation at
Rs 32.50 per equivalent full cycle (80%-DoD, 5000-cycle model), applied
identically to every stage.

### Sunny Day

| Case | Grid/day | Degr./day | Total/day | Grid Import | Grid Export |
|------|----------|-----------|-----------|-------------|-------------|
| Baseline | Rs 50.54 | Rs 0.00 | Rs 50.54 | 13.03 kWh | 11.33 kWh |
| Heuristic | Rs 28.97 | Rs 26.03 | Rs 55.01 | 5.43 kWh | 2.91 kWh |
| LP naive | Rs 24.69 | Rs 26.03 | Rs 50.72 | 5.43 kWh | 2.91 kWh |
| LP aware | Rs 26.88 | Rs 22.10 | **Rs 48.97** | 6.58 kWh | 4.18 kWh |

**On grid cost the LP saves Rs 25.85/day (51.2%) vs baseline**, and beats
the heuristic by Rs 4.29/day (14.8%).

### Cloudy Day

| Case | Grid/day | Degr./day | Total/day | Grid Import | Grid Export |
|------|----------|-----------|-----------|-------------|-------------|
| Baseline | Rs 87.14 | Rs 0.00 | Rs 87.14 | 14.68 kWh | 4.64 kWh |
| Heuristic | Rs 79.47 | Rs 14.35 | Rs 93.81 | 10.49 kWh | 0.00 kWh |
| LP naive | Rs 66.37 | Rs 24.85 | Rs 91.22 | 10.82 kWh | 0.00 kWh |
| LP aware | Rs 71.78 | Rs 14.35 | **Rs 86.13** | 10.49 kWh | 0.00 kWh |

**On grid cost the LP saves Rs 20.77/day (23.8%) vs baseline**, and beats
the heuristic by Rs 13.10/day (16.5%).

### Key Insight — and where the naive LP's margin shrinks

On **grid cost**, the optimisation gap is *wider* on the cloudy day
(16.5%) than the sunny day (14.8%). Less free solar means dispatch timing
matters more. The cloudy LP imports **more** energy than the heuristic
(10.82 vs 10.49 kWh) yet buys it Rs 13.10 more cheaply — it buys at cheap
hours and avoids expensive ones. Total energy is not the objective; *when*
it is bought is.

> [!warning] On total cost, the naive LP barely beats the heuristic
> **Heuristic Rs 93.81 vs LP naive Rs 91.22 — the naive LP is 2.76% better.**
>
> The naive LP saves Rs 13.10 of electricity but cycles 1.7x harder (EFC 0.765
> vs 0.441) and pays Rs 10.51 more in degradation. The electricity saving
> still covers the extra wear, but most of the 16.5% grid-cost advantage is
> consumed by battery life.
>
> **The degradation-aware LP keeps the heuristic's cycling level and wins
> clearly: Rs 86.13/day, Rs 5.09 below the naive LP and Rs 1.01 below the
> no-battery baseline.** See [[Stage 3 Results]].

### Why the Heuristic Underperforms on Cloudy Days

The greedy heuristic only ever charges from PV surplus — it has no
foresight, and on a cloudy day PV is scarce, so the battery never fully
fills. The LP, knowing the whole day's tariff and load in advance, can
and does **charge from the grid during cheap hours** (1.52 kWh over 2
timesteps in the cloudy case) and discharge during expensive ones. That
is a capability the heuristic structurally does not have.

It costs the naive LP something, though: it cycles harder (EFC 0.765 vs the
heuristic's 0.441) and incurs Rs 24.85/day in degradation against the
heuristic's Rs 14.35. On the sunny day both cycle identically so there is
no penalty either way; on the cloudy day the extra cycling is what cuts the
naive LP's total-cost advantage from 16.5% to 2.8%. The aware LP avoids the
over-cycling entirely.

---

## Files Involved

- `Matlab/Comparison/run_comparison.m` — main entry point
- `Matlab/Comparison/prepare_cloudy_comparison.m` — simulation runner
- `Matlab/Comparison/plot_comparison.m` — cost bars + dispatch plots
- `Matlab/Comparison/plot_ems_comparison.m` — per-stage SOC / curtailment plots
- `Matlab/Comparison/cloudy_profile_1.m` — cloudy PV profile generator
- `Matlab/Stage0/rule_based_ems_p0.m` — baseline controller
- `Matlab/Stage1/rule_based_ems_p1.m` — heuristic controller
- `Matlab/Stage2/lp_naive_ems.m` — LP controller
- `Matlab/tariff_params.m` — APDCL tariff data
- `Matlab/calculate_costs.m` — cost calculation with slab + ToD rates

---

## Related Notes

- [[README]] — full project architecture and stage breakdown
- [[Objectives and Benefits]] — value proposition and applications
- [[Evidence]] — regulatory and utility justification
- [[Stage 1 (Implementation)]] — heuristic EMS details
- [[stage_2_implementation]] — LP formulation details
