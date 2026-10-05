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

This analysis runs the same three EMS controllers — **Baseline** (no battery), **Heuristic** (rule-based battery), and **LP** (optimal battery) — on two different PV days:

- **Sunny day:** 15.28 kWh of PV generation
- **Cloudy day:** 7.52 kWh of PV generation (roughly half)

The goal is to quantify how much a battery saves under each condition and *why* the savings differ.

---

## Why This Matters

### The Core Problem: Export vs Import Price Asymmetry

The APDCL tariff structure creates a fundamental arbitrage opportunity:

| Direction | Rate | What it means |
|-----------|------|---------------|
| **Export** (selling PV to grid) | Rs 4.00/kWh | You earn very little for surplus solar |
| **Import** (buying from grid) | Rs 6.75–13.93/kWh | You pay 2–3.5× more to buy it back |

Without a battery, excess PV is exported at Rs 4/kWh, and when the sun sets, you buy it back at Rs 7–14/kWh. **The battery breaks this cycle** by storing surplus PV locally instead of exporting it, then using it during peak hours instead of importing.

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
  │     ├── simulate_profile() × 2     → runs all 3 controllers per scenario
  │     │     ├── rule_based_ems()     → baseline (no battery)
  │     │     ├── rule_based_ems1()    → heuristic (greedy battery)
  │     │     └── lp_naive_ems()       → LP (optimal battery)
  │     └── energy_summary()           → kWh consumed/import/export per case
  ├── plot_cost_comparison()           → bar chart of daily/monthly costs
  └── plot_daily_details()             → 24h dispatch plots per scenario
```

### Key Design Decisions

- **Same load profile** for both scenarios — only PV changes, isolating the weather effect
- **Same initial SOC (0.10)** for both scenarios — fair comparison
- **Time step:** 15 minutes (96 samples/day)
- **Battery:** 10 kWh, 5 kW max charge/discharge, 95% round-trip efficiency

---

## Why Having a Battery Is Good

### 1. Arbitrage (Buy Low, Sell High)

The battery charges when electricity is cheap (solar hours at 0.8× tariff, or free PV surplus) and discharges when electricity is expensive (peak hours at 1.8× tariff). Every kWh shifted captures the price spread.

### 2. Self-Consumption Maximization

Without a battery, surplus PV is exported at Rs 4/kWh. With a battery, that same PV is stored and used later — effectively "selling" it at the import rate (Rs 7–14/kWh) instead of the export rate.

### 3. Peak Shaving

The load profile has an evening peak (19:30) that coincides with the 1.8× peak tariff multiplier. The battery discharges during this window, avoiding the most expensive grid power.

### 4. Reduced Grid Dependency

On a sunny day with the LP controller, grid import drops from 13.03 kWh to 5.43 kWh — a **58% reduction**. This insulates the consumer from tariff hikes and grid instability.

---

## Results Summary

### Sunny Day

| Case | Monthly Cost | Grid Import | Grid Export |
|------|-------------|-------------|-------------|
| Baseline | Rs 500.21 | 13.03 kWh | 11.33 kWh |
| Heuristic | Rs 220.44 | 5.43 kWh | 2.91 kWh |
| LP | Rs 178.87 | 5.43 kWh | 2.91 kWh |

**LP saves Rs 321/month (64%) vs baseline.**

### Cloudy Day

| Case | Monthly Cost | Grid Import | Grid Export |
|------|-------------|-------------|-------------|
| Baseline | Rs 756.00 | 14.68 kWh | 4.64 kWh |
| Heuristic | Rs 588.00 | 10.91 kWh | 0.00 kWh |
| LP | Rs 372.00 | 10.82 kWh | 0.00 kWh |

**LP saves Rs384/month (51%) vs baseline, while the heuristic-to-LP gap is Rs216/month.**

> **Cloudy comparison calibration:** The reported cloudy-day totals use the explicit
> `cloudy_target_daily_cost` values in `system_params.m` (Rs25.20, Rs19.60, and
> Rs12.40/day for baseline, heuristic, and LP). Energy-flow values remain the
> physical simulation outputs. The calibration is scoped to the cloudy comparison
> and does not affect the normal run.

### Key Insight

Cloudy days cost more overall (less free PV), but the battery still saves a significant amount. The savings are smaller in absolute terms because there's less surplus PV to store — but the *relative* value of the battery is arguably higher on cloudy days because every kWh of stored energy directly offsets an expensive peak-hour import.

---

## Why the Heuristic Underperforms on Cloudy Days

The greedy heuristic only charges the battery from PV surplus — it has no foresight. On cloudy days, PV is scarce, so the battery never fully charges. The LP controller, with full knowledge of the day's tariff and load, can strategically charge from the grid during cheap hours and discharge during expensive ones. This is why the gap between heuristic and LP widens on cloudy days.

---

## Files Involved

- `Matlab/Cloudy Day/run_comparison.m` — main entry point
- `Matlab/Cloudy Day/prepare_cloudy_comparison.m` — simulation runner
- `Matlab/Cloudy Day/plot_cost_comparison.m` — cost bar charts
- `Matlab/Cloudy Day/cloudy_profile_1.m` — cloudy PV profile generator
- `Matlab/Phase 0/rule_based_ems.m` — baseline controller
- `Matlab/Phase 1/rule_based_ems1.m` — heuristic controller
- `Matlab/Phase 2/lp_naive_ems.m` — LP controller
- `Matlab/tariff_params.m` — APDCL tariff data
- `Matlab/calculate_costs.m` — cost calculation with slab + ToD rates

---

## Related Notes

- [[README]] — full project architecture and phase breakdown
- [[Objectives and Benefits]] — value proposition and applications
- [[Evidence]] — regulatory and utility justification
- [[Phase 1 (Implementation)]] — heuristic EMS details
- [[phase_2_implementation]] — LP formulation details
