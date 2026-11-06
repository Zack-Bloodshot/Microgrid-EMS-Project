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
  - "[[Run All Stages Comparison]]"
  - "[[Cloudy vs Sunny Comparison]]"
  - "[[Evidence]]"
---

# Simulation Results Report

> [!info] Provenance
> Every figure in this note is direct output from `run_all_stages()` and
> `prepare_cloudy_comparison()` on branch `real-simulation`.
> Nothing is hand-entered, scaled, or substituted after the run. MATLAB
> R2024b, `N = 96` timesteps at `dt = 0.25 h`.
>
> **Two views are reported throughout.** *Grid cost* is electricity
> charge only — the basis used by most published EMS comparisons.
> *Total cost* adds post-hoc battery degradation at Rs 32.50 per
> equivalent full cycle (80%-DoD, 5000-cycle model). The same model is used
> for every stage, so the rows are directly comparable. The distinction
> matters: see §1 and §4.

---

## 1. Headline Result

On the sunny day, an optimised EMS cuts the **electricity bill** by half —
and beats a greedy rule by ~15%. But once battery wear is priced, the
picture changes, and that change is the most interesting result here.

### Grid cost (electricity charge only — the published-comparison basis)

| Stage | Controller | Grid/day | Total/month | EFC |
|-------|-----------|----------|-------------|-----|
| 0 | Baseline (no battery) | Rs 50.54 | Rs 1516.10 | 0.000 |
| 1 | Heuristic (greedy) | Rs 28.97 | Rs 869.19 | 0.801 |
| 2 | LP (optimised) | Rs 24.69 | Rs 740.57 | 0.801 |

### Total cost (including battery degradation)

| Stage | Grid/day | Degradation/day | Total/day | Total/month |
|-------|----------|-----------------|-----------|-------------|
| 0 | Rs 50.54 | Rs 0.00 | **Rs 50.54** | Rs 1516.10 |
| 1 | Rs 28.97 | Rs 26.03 | **Rs 55.01** | Rs 1650.21 |
| 2 | Rs 24.69 | Rs 26.03 | **Rs 50.72** | Rs 1521.60 |

### Savings

| Comparison | Basis | Daily saving | Reduction |
|------------|-------|--------------|-----------|
| Baseline → Heuristic | Grid | Rs 21.57 | 42.7% |
| Baseline → LP | Grid | Rs 25.85 | 51.2% |
| Heuristic → LP | Grid | Rs 4.29 | **14.8%** |
| Heuristic → LP | **Total** | Rs 4.29 | **7.8%** |

> [!warning] Read the two tables together
> The battery cuts the electricity bill by **half** — that part is solid
> and matches published literature. At Rs 130,000 and the shared 80%-DoD /
> 5000-cycle model, the LP saves Rs 25.85/day of electricity but costs
> Rs 26.03/day in wear, so its **total is Rs 0.18/day above the no-battery
> baseline** (Rs 50.72 vs Rs 50.54). The heuristic is clearly worse
> (Rs 55.01). Only the degradation-aware controller in
> [[Stage 3 Results]] beats doing nothing (Rs 48.97/day).

All three stages pass power-balance and operating-limit validation with
max residual `4.441e-16 kW` against a `1e-6 kW` tolerance.

---

## 2. The Central Finding

> [!success] The optimiser's advantage is timing, not energy
> Stage 1 and Stage 2 move **identical energy** — 5.433 kWh imported,
> 2.909 kWh exported, EFC 0.801 each — yet the LP costs Rs 4.29 less per
> day. The gain is entirely in *when* energy is bought, not *how much*.

The two controllers differ in **where** that identical 5.433 kWh lands:

| Import window | Rate | Stage 1 (Heuristic) | Stage 2 (LP) | Change |
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

| | Stage 1 | Stage 2 |
|---|---------|---------|
| Gross energy cost | Rs 38.2773 | Rs 33.9901 |
| Export credit (2.909 kWh × Rs 4.00) | − Rs 11.6377 | − Rs 11.6377 |
| Fixed charge (Rs 70/30) | + Rs 2.3333 | + Rs 2.3333 |
| **Grid cost** | **Rs 28.9729** | **Rs 24.6857** |
| Post-hoc degradation (EFC 0.801 × Rs 32.50) | + Rs 26.03 | + Rs 26.03 |
| **Total** | **Rs 55.01** | **Rs 50.72** |

Both controllers carry **identical** degradation cost (same EFC), so the
grid-cost saving of Rs 4.29 passes straight through to the total. On this
day the LP's advantage is pure timing, with no degradation penalty either
way. Both totals sit above the no-battery baseline once the shared wear
model is applied.

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

This is the whole Stage 1 vs Stage 2 argument in six rows: the greedy
controller spends its battery on the first deficit it sees, while the
optimiser reserves it for the most expensive deficit it knows is coming.

---

## 4. Cloudy Day — Where the Result Reverses

Cloudy PV: **6.942 kWh** (peak 1.80 kW) vs sunny 15.279 kWh — 45% of
available solar.

### Grid cost

| Case | Grid/day | Import | Export | EFC |
|------|----------|--------|--------|-----|
| Baseline | Rs 87.14 | 14.679 kWh | 4.640 kWh | 0.000 |
| Heuristic | Rs 79.47 | 10.492 kWh | 0.00 kWh | 0.441 |
| LP | Rs 66.37 | 10.823 kWh | 0.00 kWh | 0.765 |

**On grid cost alone the LP wins by 16.48%** — slightly *more* than on
the sunny day (14.80%). Less free solar means dispatch timing matters
more.

### Total cost

| Case | Grid/day | Degradation/day | Total/day |
|------|----------|-----------------|-----------|
| Baseline | Rs 87.14 | Rs 0.00 | **Rs 87.14** |
| Heuristic | Rs 79.47 | Rs 14.35 | **Rs 93.81** |
| LP | Rs 66.37 | Rs 24.85 | **Rs 91.22** |

> [!warning] The LP wins, but wear eats most of the margin
> **Heuristic Rs 93.81 vs LP Rs 91.22 — the LP is 2.76% better.**
>
> The LP buys Rs 13.10 less electricity but cycles 1.7× harder (EFC 0.765
> vs 0.441) and pays Rs 10.51 more in degradation. The electricity saving
> still covers the extra wear, but the margin is far smaller than the 16.48%
> grid-cost advantage suggests.

This is why the degradation model matters. The naive LP is over-cycling to
chase marginal savings that battery wear consumes. The degradation-aware
Stage 3 controller trims that marginal cycling (EFC 0.765 → 0.441) and lands
well below this Stage 2 result (Rs 86.13 vs Rs 91.22/day). See
[[Stage 3 Results]].

### The capability the heuristic lacks

On the cloudy day the LP buys **1.519 kWh from the grid across 2
timesteps** during cheap solar hours to charge the battery. The greedy
rule only ever charges from PV surplus — it has no foresight, so on a
scarce-PV day it never fills the battery (EFC 0.441 vs 0.765).

That grid-charging capability is real and worth keeping. The problem is
purely that the LP pays for it in battery life, and its objective
function is blind to that cost.

### Net position

| Basis | Heuristic | LP | LP advantage |
|-------|-----------|----|--------------|
| Grid cost | Rs 79.47 | Rs 66.37 | **+16.48%** |
| Total cost | Rs 93.81 | Rs 91.22 | **+2.76%** |

The grid-cost view matches the published literature. The total-cost view
shows how much of that advantage battery wear consumes. Both are worth
reporting.

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

**Fairness fix:** Stage 1 previously reported `degradation_cost = 0`
despite cycling the battery heavily. Charging it only to Stage 2 — the
stage that *benefits* from the omission — overstated the LP's advantage.
Both battery stages now report post-hoc degradation.

### Verification performed

| Check | Result |
|-------|--------|
| Power balance, all stages | Max residual 4.441e-16 kW (tol 1e-6) |
| SOC bounds, all stages | Within [0.10, 0.90] |
| Grid and battery power limits | All within bounds |
| Simultaneous charge/discharge | None |
| Stage 2 grid cost cross-check | `lp_naive_ems` vs `calculate_costs` — equal |
| Stage 2 degradation cross-check | `lp_naive_ems` vs `battery_degradation` — equal |
| Shared degradation model | Stage 1/2/3 all use `battery_degradation.m` |
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

1. **Degradation-aware LP (Stage 3).** Implemented. On the cloudy day it
   trims EFC from 0.765 to 0.441 and lands Rs 5.09/day below the naive LP
   (Rs 86.13 vs Rs 91.22). See [[Stage 3 Results]].
2. **Multi-day horizon.** Required to exercise the 300/500 kWh slabs and
   to make monthly figures simulated rather than extrapolated.
3. **Measured or TMY-driven profiles** to replace the parametric curves.
4. **Regenerate the technical report and slides** — both currently quote
   pre-correction figures (e.g. Rs 178.87/month) that are roughly 4×
   off from this branch's output.

---

## Related

- [[System Parameters & Tariff]] — parameter and tariff reference
- [[Run All Stages Comparison]] — sunny-day stage comparison
- [[Cloudy vs Sunny Comparison]] — weather sensitivity
- [[Evidence]] — APDCL source documents
- [[Objectives and Benefits]] — value proposition
