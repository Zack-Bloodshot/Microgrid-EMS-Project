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
  │     ├── simulate_day() × 2         → runs all 3 controllers per scenario
  │     │     ├── rule_based_ems_p0()  → baseline (no battery)
  │     │     ├── rule_based_ems_p1()  → heuristic (greedy battery)
  │     │     └── lp_naive_ems()       → LP (optimal battery)
  │     └── energy_summary()           → kWh consumed/import/export per case
  ├── plot_comparison()               → cost bars + 24h dispatch plots
  └── plot_ems_comparison()           → per-phase SOC / curtailment plots
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

### Sunny Day

| Case | Cost/day | Cost/month (×30) | Grid Import | Grid Export |
|------|----------|------------------|-------------|-------------|
| Baseline | Rs 50.54 | Rs 1516.10 | 13.03 kWh | 11.33 kWh |
| Heuristic | Rs 29.65 | Rs 889.63 | 5.43 kWh | 2.91 kWh |
| LP | Rs 25.28 | Rs 758.37 | 5.43 kWh | 2.91 kWh |

**LP saves Rs 25.26/day (50.0%) vs baseline.** The heuristic→LP gap is
Rs 4.37/day (14.7%).

### Cloudy Day

| Case | Cost/day | Cost/month (×30) | Grid Import | Grid Export |
|------|----------|------------------|-------------|-------------|
| Baseline | Rs 87.14 | Rs 2614.20 | 14.68 kWh | 4.64 kWh |
| Heuristic | Rs 79.71 | Rs 2391.30 | 10.49 kWh | 0.00 kWh |
| LP | Rs 67.11 | Rs 2013.30 | 10.82 kWh | 0.00 kWh |

**LP saves Rs 20.03/day (23.0%) vs baseline.** The heuristic→LP gap is
Rs 12.60/day (15.8%) — proportionally *larger* than on the sunny day,
even though the absolute saving is smaller.

### Key Insight

Cloudy days cost more overall (less free PV), so every case is worse in
rupees. But the *optimisation gap* — what foresight is worth — is
proportionally wider on the cloudy day (15.8% vs 14.7%), because there
is less free energy to fall back on and dispatch timing matters more.

Note that the cloudy LP imports **more** energy than the heuristic
(10.82 vs 10.49 kWh) yet still costs **Rs 12.60 less**. It buys that
extra kWh at cheap hours and avoids expensive ones. Total energy is not
the objective; *when* it is bought is.

### Why the Heuristic Underperforms on Cloudy Days

The greedy heuristic only ever charges from PV surplus — it has no
foresight, and on a cloudy day PV is scarce, so the battery never fully
fills. The LP, knowing the whole day's tariff and load in advance, can
and does **charge from the grid during cheap hours** (1.52 kWh over 2
timesteps in the cloudy case) and discharge during expensive ones. That
is a capability the heuristic structurally does not have.

It costs the LP something, though: it cycles harder (EFC 0.765 vs the
heuristic's 0.441) and incurs 3× the degradation cost (Rs 0.75 vs Rs
0.25 per day). It still wins overall, but this is exactly the
cost-vs-degradation tension that motivates a degradation-aware Phase 3.

---

## Files Involved

- `Matlab/Comparison/run_comparison.m` — main entry point
- `Matlab/Comparison/prepare_cloudy_comparison.m` — simulation runner
- `Matlab/Comparison/plot_comparison.m` — cost bars + dispatch plots
- `Matlab/Comparison/plot_ems_comparison.m` — per-phase SOC / curtailment plots
- `Matlab/Comparison/cloudy_profile_1.m` — cloudy PV profile generator
- `Matlab/Phase0/rule_based_ems_p0.m` — baseline controller
- `Matlab/Phase1/rule_based_ems_p1.m` — heuristic controller
- `Matlab/Phase2/lp_naive_ems.m` — LP controller
- `Matlab/tariff_params.m` — APDCL tariff data
- `Matlab/calculate_costs.m` — cost calculation with slab + ToD rates

---

## Related Notes

- [[README]] — full project architecture and phase breakdown
- [[Objectives and Benefits]] — value proposition and applications
- [[Evidence]] — regulatory and utility justification
- [[Phase 1 (Implementation)]] — heuristic EMS details
- [[phase_2_implementation]] — LP formulation details
