---
title: Simulation Results Report
date: 2026-10-15
tags:
  - FYP
  - EMS
  - results
  - simulation
  - verification
status: verified
related:
  - "[[System Parameters & Tariff]]"
  - "[[Run All Phases Comparison]]"
  - "[[Cloudy vs Sunny Comparison]]"
  - "[[Evidence]]"
---

# Simulation Results Report

> [!info] Provenance
> Every figure in this note is direct output from `run_all_phases()` and
> `prepare_cloudy_comparison()` on branch `real-simulation` @ `6a27a28`.
> Nothing is hand-entered, scaled, or substituted after the run. MATLAB
> R2024b, `N = 96` timesteps at `dt = 0.25 h`.

---

## 1. Headline Result

On the sunny day, adding an optimised EMS cuts the electricity bill by
**half**.

| Phase | Controller | Grid/day | Degradation/day | **Total/day** | Total/month | EFC |
|-------|-----------|----------|-----------------|---------------|-------------|-----|
| 0 | Baseline (no battery) | Rs 50.54 | Rs 0.00 | **Rs 50.54** | Rs 1516.10 | 0.000 |
| 1 | Heuristic (greedy) | Rs 28.97 | Rs 0.68 | **Rs 29.65** | Rs 889.63 | 0.801 |
| 2 | LP (optimised) | Rs 24.69 | Rs 0.59 | **Rs 25.28** | Rs 758.37 | 0.801 |

### Savings

| Comparison | Daily saving | Reduction |
|------------|--------------|-----------|
| Baseline → Heuristic | Rs 20.88 | **41.3%** |
| Baseline → LP | Rs 25.26 | **50.0%** |
| Heuristic → LP | Rs 4.38 | **14.8%** |

All three phases pass power-balance and operating-limit validation with
max residual `4.441e-16 kW` against a `1e-6 kW` tolerance.

---

## 2. The Central Finding

> [!success] The optimiser's advantage is timing, not energy
> Phase 1 and Phase 2 move **identical energy** — 5.433 kWh imported,
> 2.909 kWh exported, EFC 0.801 each — yet the LP costs Rs 4.38 less per
> day. The gain is entirely in *when* energy is bought, not *how much*.

The two controllers differ in **where** that identical 5.433 kWh lands:

| Import window | Rate | Phase 1 (Heuristic) | Phase 2 (LP) | Change |
|---------------|------|----------------------|--------------|--------|
| Normal (22–09) | Rs 6.75 | 4.245 kWh | 3.445 kWh | −0.800 |
| Solar (09–17) | Rs 5.40 | 0.000 kWh | 1.988 kWh | +1.988 |
| **Peak (17–22)** | **Rs 8.10** | **1.188 kWh** | **0.000 kWh** | **−1.188** |
| **Total** | | **5.433 kWh** | **5.433 kWh** | **0** |

**The heuristic imports 1.188 kWh during the most expensive hours of the
day. The LP imports exactly zero.** It shifts that energy into solar
hours where it costs Rs 2.70/kWh less.

### Cost reconciliation

The **grid-cost** saving (Rs 4.29) is fully explainable by the timing shift:

```
1.188 kWh × (Rs 8.10 − Rs 5.40) = Rs 3.21   peak → solar shift
0.800 kWh × (Rs 6.75 − Rs 5.40) = Rs 1.08   normal → solar shift
                                   ─────────
                                    Rs 4.29   = Rs 4.2872 observed
```

Full bill reconstruction (both verified against `calculate_costs`):

| | Phase 1 | Phase 2 |
|---|---------|---------|
| Gross energy cost | Rs 38.2773 | Rs 33.9901 |
| Export credit (2.909 kWh × Rs 4.00) | − Rs 11.6377 | − Rs 11.6377 |
| Fixed charge (Rs 70/30) | + Rs 2.3333 | + Rs 2.3333 |
| **Grid cost** | **Rs 28.9729** | **Rs 24.6857** |
| Post-hoc degradation | + Rs 0.6813 | + Rs 0.5933 |
| **Total** | **Rs 29.6542** | **Rs 25.2790** |

Note the total saving (Rs 4.38) is slightly larger than the grid saving
(Rs 4.29): Phase 1 carries Rs 0.09 *more* degradation cost despite
cycling identically, because its discharge is spread over more, smaller
episodes rather than two deep ones.

This is the cleanest possible demonstration that the optimisation does
real work: both controllers cycle the battery identically hard, so the
gap cannot be attributed to better energy management — only to better
*scheduling*.

---

## 3. Hourly Dispatch (Sunny Day)

Hourly averages over each 4-step block.

| Hour | PV | Load | P0 imp | P0 exp | P1 ch | P1 dis | P1 imp | P1 SOC | P2 ch | P2 dis | P2 imp | P2 SOC |
|-----:|----:|-----:|-------:|-------:|------:|-------:|-------:|-------:|------:|-------:|-------:|-------:|
| 01 | 0.00 | 0.26 | 0.26 | 0.00 | 0.00 | 0.00 | 0.26 | 0.10 | 0.00 | 0.00 | 0.26 | 0.10 |
| 02 | 0.00 | 0.26 | 0.26 | 0.00 | 0.00 | 0.00 | 0.26 | 0.10 | 0.00 | 0.00 | 0.26 | 0.10 |
| 03 | 0.00 | 0.26 | 0.26 | 0.00 | 0.00 | 0.00 | 0.26 | 0.10 | 0.00 | 0.00 | 0.26 | 0.10 |
| 04 | 0.00 | 0.26 | 0.26 | 0.00 | 0.00 | 0.00 | 0.26 | 0.10 | 0.00 | 0.00 | 0.26 | 0.10 |
| 05 | 0.00 | 0.27 | 0.27 | 0.00 | 0.00 | 0.00 | 0.27 | 0.10 | 0.00 | 0.00 | 0.27 | 0.10 |
| 06 | 0.00 | 0.34 | 0.34 | 0.00 | 0.00 | 0.00 | 0.34 | 0.10 | 0.00 | 0.00 | 0.34 | 0.10 |
| 07 | 0.01 | 0.59 | 0.58 | 0.00 | 0.00 | 0.00 | 0.58 | 0.10 | 0.00 | 0.00 | 0.58 | 0.10 |
| 08 | 0.14 | 0.94 | 0.80 | 0.00 | 0.00 | 0.00 | 0.80 | 0.10 | 0.00 | 0.00 | 0.80 | 0.10 |
| 09 | 0.61 | 1.00 | 0.39 | 0.00 | 0.00 | 0.00 | 0.39 | 0.10 | 0.00 | 0.00 | 0.39 | 0.10 |
| 10 | 1.39 | 0.68 | 0.00 | 0.71 | 0.71 | 0.00 | 0.00 | 0.10 | 0.65 | 0.00 | 0.00 | 0.10 |
| 11 | 2.26 | 0.38 | 0.00 | 1.87 | 1.87 | 0.00 | 0.00 | 0.17 | 1.79 | 0.00 | 0.00 | 0.16 |
| 12 | 2.86 | 0.28 | 0.00 | 2.58 | 2.58 | 0.00 | 0.00 | 0.35 | 1.30 | 0.00 | 0.00 | 0.33 |
| 13 | 2.93 | 0.27 | 0.00 | 2.67 | 2.67 | 0.00 | 0.00 | 0.59 | 2.00 | 0.00 | 0.00 | 0.46 |
| 14 | 2.45 | 0.27 | 0.00 | 2.18 | 0.59 | 0.00 | 0.00 | 0.84 | 2.18 | 0.00 | 0.00 | 0.65 |
| 15 | 1.61 | 0.37 | 0.00 | 1.24 | 0.00 | 0.00 | 0.00 | 0.90 | 0.42 | 0.00 | 0.00 | 0.85 |
| 16 | 0.78 | 1.21 | 0.52 | 0.09 | 0.00 | 0.52 | 0.00 | 0.90 | 0.09 | 0.35 | 0.17 | 0.89 |
| 17 | 0.23 | 2.05 | 1.82 | 0.00 | 0.00 | 1.82 | 0.00 | 0.85 | 0.00 | 0.00 | 1.82 | 0.86 |
| 18 | 0.02 | 1.37 | 1.35 | 0.00 | 0.00 | 1.35 | 0.00 | 0.65 | 0.00 | 1.35 | 0.00 | 0.86 |
| 19 | 0.00 | 1.30 | 1.30 | 0.00 | 0.00 | 1.30 | 0.00 | 0.51 | 0.00 | 1.30 | 0.00 | 0.72 |
| 20 | 0.00 | 1.56 | 1.56 | 0.00 | 0.00 | 1.56 | 0.00 | 0.37 | 0.00 | 1.56 | 0.00 | 0.58 |
| 21 | 0.00 | 1.36 | 1.36 | 0.00 | 0.00 | 1.05 | 0.31 | 0.21 | 0.00 | 1.36 | 0.00 | 0.42 |
| 22 | 0.00 | 0.87 | 0.87 | 0.00 | 0.00 | 0.00 | 0.87 | 0.10 | 0.00 | 0.87 | 0.00 | 0.28 |
| 23 | 0.00 | 0.48 | 0.48 | 0.00 | 0.00 | 0.00 | 0.48 | 0.10 | 0.00 | 0.48 | 0.00 | 0.18 |
| 24 | 0.00 | 0.32 | 0.32 | 0.00 | 0.00 | 0.00 | 0.32 | 0.10 | 0.00 | 0.32 | 0.00 | 0.13 |

### What the table shows

**Hours 16–21 — the divergence.** Both controllers face the evening peak
window (17:00–22:00). At hour 16 the heuristic discharges hard (0.52 kW)
to cover the load spike, draining SOC from 0.90 to 0.85 while importing
nothing. The LP discharges only 0.35 kW and imports 0.17 kWh — a small
penalty at 1.2× — deliberately **holding charge back** for the deeper peak
window that follows.

**Hour 21 — the heuristic runs dry.** The heuristic discharges 1.05 kW
but still imports 0.31 kWh, and SOC falls to 0.10 — the floor. It is out
of energy with peak hours still ahead. The LP, having reserved, discharges
its full 1.36 kW and imports **nothing**.

**Hour 22 — the cost of myopia.** SOC 0.10 vs 0.28. The heuristic is
empty and must buy 0.87 kWh at whatever price the clock says. The LP
still holds 28% charge, worth about 2.8 kWh.

This is the whole Phase 1 vs Phase 2 argument in six rows: the greedy
controller spends its battery on the first deficit it sees, while the
optimiser reserves it for the most expensive deficit it knows is coming.

---

## 4. Cloudy Day

Cloudy PV: **6.942 kWh** (peak 1.80 kW) vs sunny 15.279 kWh — 45% of
available solar.

| Case | Grid/day | Degradation/day | Total/day | Total/month | Import | Export | EFC |
|------|----------|-----------------|-----------|--------------|--------|--------|-----|
| Baseline | Rs 87.14 | Rs 0.00 | **Rs 87.14** | Rs 2614.22 | 14.679 kWh | 4.640 kWh | 0.000 |
| Heuristic | Rs 79.47 | Rs 0.25 | **Rs 79.71** | Rs 2391.37 | 10.492 kWh | 0.00 kWh | 0.441 |
| LP | Rs 66.37 | Rs 0.75 | **Rs 67.11** | Rs 2013.40 | 10.823 kWh | 0.00 kWh | 0.765 |

### Savings

| Comparison | Daily saving | Reduction |
|------------|--------------|-----------|
| Baseline → Heuristic | Rs 7.43 | 8.5% |
| Baseline → LP | Rs 20.03 | **23.0%** |
| Heuristic → LP | Rs 12.60 | **15.8%** |

### Two findings worth noting

**1. The optimisation gap widens on cloudy days.** Heuristic → LP is
15.8% on the cloudy day versus 14.8% on the sunny day. With less free
solar to fall back on, dispatch timing matters *more*, not less.

**2. The LP grid-charges; the heuristic structurally cannot.** On the
cloudy day the LP buys **1.519 kWh from the grid across 2 timesteps**
during cheap solar hours to charge the battery. The heuristic only ever
charges from PV surplus — it has no foresight, so on a scarce-PV day it
never fills the battery (EFC 0.441 vs 0.765).

Note the LP imports *more* energy than the heuristic (10.823 vs 10.492
kWh) yet costs Rs 12.60 less. Again: **when**, not **how much**.

### The cost of that advantage

The LP cycles roughly 1.7× harder and incurs **3× the degradation cost**
(Rs 0.75 vs Rs 0.25/day). It still wins by a wide margin, but this is
exactly the cost-versus-degradation tension that motivates a
degradation-aware Phase 3 — the naive LP is not penalised for the
throughput it adds.

---

## 5. System Under Test

| Parameter | Value |
|-----------|-------|
| PV rated power | 3 kW |
| Battery capacity | 10 kWh |
| Max charge / discharge | 5 kW / 5 kW (0.5C) |
| SOC range | 0.10 – 0.90 |
| Charge / discharge efficiency | 0.95 / 0.95 |
| Grid import / export limit | 5 kW / 5 kW |
| Time step | 0.25 h (96 steps/day) |
| PV energy (sunny / cloudy) | 15.279 / 6.942 kWh |
| Load energy | 16.981 kWh (peak 2.15 kW at 16:00) |
| Replacement cost | Rs 130,000 |

### Tariff (APDCL FY2026-27, LT-III Domestic-B)

| Window | Hours | Multiplier | Rate |
|--------|-------|-----------|------|
| Solar | 09:00–17:00 | 0.80× | Rs 5.40/kWh |
| Normal | 22:00–09:00 | 1.00× | Rs 6.75/kWh |
| Peak | 17:00–22:00 | 1.20× | Rs 8.10/kWh |
| Export credit | — | — | Rs 4.00/kWh (assumed) |

Fixed charge Rs 70/month (pro-rated Rs 2.33/day).

---

## 6. Why These Numbers Are Defensible

> [!note] Audit trail
> This branch exists specifically because earlier results were not
> defensible. The following were removed and their effect eliminated.

| Removed | Was |
|---------|-----|
| `cloudy_target_daily_cost` | `[25.2, 20.1, 16.5]` written over simulated output |
| `apply_cloudy_cost_targets()` | Function that overwrote every cloudy-day total with those constants |
| `heuristic_SOC_min = 0.1742` | Reserve floor reverse-engineered to hit those targets |
| `billing_scale = 0.2175` | Arbitrary factor shrinking every bill ~4.6× |

**Tariff corrections against the source notice:**

- Peak ToD multiplier **1.60 → 1.20** — the APDCL notice specifies peak
  hours at 120% of normal energy charges. The code previously used 1.60
  and the project notes said 1.80; both were wrong.
- `Cost_replacement` **150,000 → 130,000** Rs, matching project notes.

**Fairness fix:** Phase 1 previously reported `degradation_cost = 0`
despite cycling the battery heavily. Charging it only to Phase 2 — the
phase that *benefits* from the omission — overstated the LP's advantage.
Both battery phases now report post-hoc degradation.

### Verification performed

| Check | Result |
|-------|--------|
| Power balance, all phases | Max residual 4.441e-16 kW (tol 1e-6) |
| SOC bounds, all phases | Within [0.10, 0.90] |
| Grid and battery power limits | All within bounds |
| Simultaneous charge/discharge | None |
| Phase 2 grid cost cross-check | `lp_naive_ems` vs `calculate_costs` — equal |
| Phase 2 degradation cross-check | `lp_naive_ems` vs `battery_degradation` — equal |
| Bill reconstruction | Recomputed independently, matches to 4 decimals |
| Cost decomposition | Rs 4.29 predicted saving vs Rs 4.29 observed |
| MATLAB warnings | None |

---

## 7. Limitations

Carried forward from [[System Parameters & Tariff]]:

1. **Monthly slabs are never exercised.** A single day imports ~13 kWh,
   so all energy falls in the first 300 kWh slab. The slab allocator is
   correct but inert at this scale.
2. **"Monthly" is `30 × daily` extrapolation**, not a simulated month.
   Real consumption is seasonal and day-to-day variable.
3. **Profiles are parametric.** PV is a shaped cosine, load is a sum of
   Gaussians. Representative, not measured.
4. **Terminal SOC is unconstrained** in the LP. Acceptable for a single
   self-contained day, and no exploit exists since PV generation ends at
   18:00. Must be revisited if the horizon spans multiple days.
5. **Export rate Rs 4.00 is an assumption**, not published by APDCL. It
   is favourable to the baseline (which exports most), so the battery's
   advantage is not overstated by it.

---

## 8. Next Steps

1. **Degradation-aware LP (Phase 3).** The cloudy-day result shows the
   naive LP cycling 1.7× harder than necessary at 3× the degradation
   cost. Folding a per-cycle cost into the objective should close some
   of that gap while keeping most of the Rs 12.60/day saving.
2. **Multi-day horizon.** Required to exercise the 300/500 kWh slabs and
   to make monthly figures simulated rather than extrapolated.
3. **Measured or TMY-driven profiles** to replace the parametric curves.
4. **Regenerate the technical report and slides** — both currently quote
   pre-correction figures (e.g. Rs 178.87/month) that are roughly 4×
   off from this branch's output.

---

## Related

- [[System Parameters & Tariff]] — parameter and tariff reference
- [[Run All Phases Comparison]] — sunny-day phase comparison
- [[Cloudy vs Sunny Comparison]] — weather sensitivity
- [[Evidence]] — APDCL source documents
- [[Objectives and Benefits]] — value proposition
