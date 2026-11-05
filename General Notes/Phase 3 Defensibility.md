---
title: Phase 3 Defensibility
date: 2026-11-05
tags:
  - FYP
  - EMS
  - phase-3
  - defensibility
  - degradation
status: verified
related:
  - "[[Phase 3 Results]]"
  - "[[Defensibility Analysis]]"
  - "[[Simulation Results Report]]"
  - "[[System Parameters & Tariff]]"
---

# Phase 3 Defensibility — "Is the battery even worth it?"

> [!info] Provenance
> Every number here is from the production pipeline on `real-simulation`,
> MATLAB R2024b, re-run 2026-11-05 via `simulate_day()` with the published
> tariff. Nothing is hand-entered. See the reproduction block at the end.

## TL;DR

| Question | Answer |
|---|---|
| Did Phase 3 destroy the Phase 1/2 gains? | **No.** The *grid* savings are unchanged (43% / 51%). What collapsed was the *net* saving, because the earlier wear model was ~59× too cheap. |
| Is the battery "useless"? | On energy arbitrage at APDCL FY2026-27, **almost exactly break-even**: it captures Rs 25.85/day of grid value at a cost of Rs 26.03/day of wear. |
| Then why Phase 3? | It is the **only** controller that is net-positive (Rs 1.56/day) because it refuses the negative-margin trades Phase 1 and 2 make. |
| Why is degradation ≈ grid cost? | Wear is capex amortisation: Rs 130,000 over ~13.7 years ≈ Rs 26/day. The whole grid bill is Rs 27/day. Same order by construction. |
| Is the result robust? | **No — it is knife-edge.** Four assumptions each sit 2–9% from their break-even. That is the honest headline, and it is a *result*, not a failure. |
| Is XGBoost the fix? | No. This LP has perfect foresight, so Rs 1.56/day is an **upper bound**. Better forecasting can only shrink it. |

---

## 1. What actually changed since the last seminar

The progress seminar showed Phase 0/1/2 with large savings. Those savings
were real, but they were **grid-cost** savings under a wear model that
understated battery degradation by ~59× (Rs 0.59/day). The correction did
not change the dispatch; it changed the accounting.

| Metric | Phase 0 | Phase 1 | Phase 2 | Phase 3 |
|---|---:|---:|---:|---:|
| Grid cost [Rs/day] | 50.54 | 28.97 | 24.69 | 26.88 |
| Grid saving vs P0 | — | 21.56 (42.7%) | 25.85 (51.1%) | 23.66 (46.8%) |
| Wear [Rs/day] | 0.00 | 26.03 | 26.03 | 22.10 |
| **Total [Rs/day]** | **50.54** | **55.01** | **50.72** | **48.97** |
| Net vs P0 | — | −4.47 | −0.18 | **+1.56** |

**Say this:** *"Between seminars I found a 59× error in my degradation model
and fixed it. The grid savings did not move — 43% and 51% — but the net
economics did. That correction is the most important result in the project,
because it shows the naive optimiser was destroying value."*

Self-correction is a strength in a viva. Hiding it is not.

---

## 2. The one line that explains everything

One kWh delivered by the battery requires:

| Quantity | Value |
|---|---:|
| Energy drawn from source (PV or grid) | 1.108 kWh |
| Battery throughput (charge + discharge) | 2.161 kWh |
| Wear at Rs 1.625/kWh throughput | **Rs 3.51** |
| Peak − solar price spread (Rs 8.10 − 5.40) | **Rs 2.70** |

> **The wear cost of one delivered kWh (Rs 3.51) is larger than the entire
> peak-to-solar price spread (Rs 2.70).**
> Grid-charging arbitrage is impossible *by construction*, for any algorithm.

The only surviving trade is charging from **PV that would otherwise be
exported**, because then the "fuel" costs only the forgone export credit:

| Charge source | Break-even peak price | Actual peak (Rs 8.10) |
|---|---:|---|
| PV surplus, forgoing Rs 4.00 export | **Rs 7.94** | profitable, +Rs 0.16/kWh |
| Grid @ solar rate (5.40) | Rs 9.49 | impossible |
| Grid @ normal rate (6.75) | Rs 10.99 | impossible |

So Phase 3's entire positive result is `Rs 0.16/kWh × ~6.5 kWh/day ≈ Rs 1`.
Everything else is the LP refusing to lose money.

---

## 3. Why Phase 2 loses and Phase 3 wins — the exact trade

Peak-window dispatch is **identical** in Phases 2 and 3: both import
**zero** kWh from 17:00 to 22:00 and cover the 6.46 kWh evening peak from
the battery. The difference is entirely elsewhere:

| | Phase 2 | Phase 3 | Δ |
|---|---:|---:|---:|
| Charged [kWh] | 8.421 | 7.147 | −1.274 |
| Discharged [kWh] | 7.600 | 6.450 | −1.150 |
| Extra wear | | | −Rs 3.94 |
| Extra grid saving | | | +Rs 2.19 |
| **Net** | | | **−Rs 1.75** |

The extra 1.15 kWh is discharged at **normal-price hours 15:00, 22:00 and
23:00**, not at peak. Phase 2 is arbitraging a **Rs 1.35** spread
(normal 6.75 vs solar 5.40) against a **Rs 3.51** wear cost.

> *"Phase 2 is not badly scheduled — it is correctly scheduling a trade that
> is unprofitable. Phase 3's contribution is knowing when to stop."*

This is also why the battery looks "unused": the profitable work is already
done by 0.68 EFC. It covers the whole peak window and stops.

---

## 4. Why the battery isn't doing "storage"

Three structural reasons, all defensible:

1. **There is no off-peak tariff.** Cheapest grid energy is solar hours
   (5.40×), dearest is peak (8.10×). Spread 2.70 < wear 3.51. A battery has
   nothing to buy low and sell high.
2. **PV ≈ load.** 15.28 kWh generated vs 16.98 kWh consumed. The residual to
   arbitrage is small; Phase 0 only imports 13.03 kWh and exports 11.33 kWh
   in a day.
3. **The battery starts empty** (`SOC0 = SOC_min = 0.1`) and must return to
   0.1 (`SOC(N+1) ≥ SOC0`). It can only shift *same-day* PV. No multi-day
   storage, no overnight inventory.

The battery *is* doing storage — a single daily solar→evening transfer,
SOC 0.10 → 0.78 → 0.10. That is the economically correct amount at this
tariff. It is not an algorithm failure.

---

## 5. The break-even frontier (the actual deliverable)

Every one of these is a single-parameter sweep of the production pipeline.

| Parameter | Assumed | Break-even | Margin | If wrong, result flips |
|---|---:|---:|---:|---|
| ToD peak multiplier | 1.20 | **1.177** | +2% | battery idles, gain → 0 |
| Export credit | Rs 4.00 | **Rs 4.22** | −5% | battery idles, gain → 0 |
| Rated cycle life | 5000 | **~4650** | +7% | battery idles, gain → 0 |
| Battery cost | Rs 130,000 | **~Rs 142,000** | +9% | battery idles, gain → 0 |
| α (wear weight) | 1.00 | **1.08** | +8% | battery idles, gain → 0 |

Two readings, and you must choose one and defend it:

- **Optimistic:** APDCL's actual 1.20 peak multiplier sits *just above* the
  1.177 activation threshold — the tariff is (barely) storage-viable.
- **Pessimistic:** the positive result lives in a parameter box ~5% wide.
  Three of the five inputs are labelled assumptions in your own notes.

**Do not present Rs 1.56/day as a headline without this table.** The table
*is* the contribution: it converts "does the battery pay?" into "under what
tariff does the battery pay?" — which is a publishable, defensible claim.

### One place where the answer gets much better

The wear model prices every kWh at 80% DoD, but the actual Phase 3 cycle
depth is **0.679**. Your own `b_cycle = 1.3` gives
`N(0.679) = 5000 × (0.679/0.80)^−1.3 = 6188` cycles, i.e. `c_deg = 1.31`
instead of 1.625:

| | Fixed 80% DoD (headline) | Depth-corrected |
|---|---:|---:|
| Phase 3 wear [Rs/day] | 22.10 | 17.85 |
| Phase 3 total [Rs/day] | 48.97 | **44.73** |
| Net vs Phase 0 | +1.56 | **+5.81** |

Phase 2 cycles at the full 0.80 swing, so its wear does **not** improve. The
conservative model therefore *understates* Phase 3's advantage. That is a
strong defence: *"my headline uses the most pessimistic wear model I have;
the depth-aware one widens the gap."*

---

## 6. Two methodological holes an examiner will find

### 6.1 Phase 2 has no terminal-SOC constraint — the comparison is only fair at SOC0 = 0.1

Phase 2 is allowed to end the day below its starting SOC; Phase 3 is not.
At `SOC0 = 0.1 = SOC_min` there is nothing to liquidate, so the comparison
is exactly fair. Move the start SOC and Phase 2 "wins" by spending free
inventory:

| SOC0 | P0 | Phase 2 (unguarded) | Phase 2 (+ terminal guard) | Phase 3 |
|---:|---:|---:|---:|---:|
| 0.1 | 50.54 | 50.72 | 50.72 | 48.97 |
| 0.3 | 50.54 | 40.98 | **53.36** | 49.16 |
| 0.5 | 50.54 | 30.85 | **60.87** | 49.62 |

The unguarded numbers are an artefact: Phase 2 is cashing in ~4 kWh of
stored energy it never paid for. **Fix:** add the same `SOC(N+1) ≥ SOC0`
row to `lp_naive_ems` and re-run the SOC0 sweep, or state explicitly that
SOC0 = SOC_min is the only comparable point.

### 6.2 `LifeCycles` is computed but never used

`battery_degradation.m` documents a depth-dependent `LifeCycles` curve and
then prices throughput flat at 80% DoD. That is conservative and defensible,
but you must be able to say *why* you price at 0.80 when your own diagnostic
says the cycle is 0.679. Answer: cycle-level depth accounting needs rainflow
counting; the flat model is the conservative upper bound on wear.

---

## 7. "What's the point of the project?" — the honest answer

The project is not "a battery saves money". It is:

> **A method for deciding how much a battery should cycle when wear is
> priced like fuel.** At APDCL FY2026-27 the answer is "very little":
> 0.68 EFC/day, worth Rs 1.56/day on a Rs 130,000 asset (0.44%/yr — worse
> than a fixed deposit). The optimiser's value is not the Rs 1.56; it is
> that the greedy and naive controllers are **negative** (−Rs 4.47 and
> −Rs 0.18) at the same tariff.

Why that is a legitimate FYP:

1. It is a **quantified negative result with a boundary**, not a bug.
2. It reproduces the *direction* of published work (optimisation beats
   heuristics) while correcting the **magnitude** — a genuine contribution.
3. The break-even frontier is directly useful to a household or a regulator:
   it says how much the peak multiplier must rise (or the battery price
   fall) before storage pays.
4. It motivates the real value streams you have correctly excluded:
   **backup/resilience**, **subsidy** (PM-Surya Ghar ≈ Rs 1,23,000, ~95% of
   battery capex), and demand-charge avoidance on commercial tariffs.

What it is **not**: a demonstration that "optimisation saves 50%". That
claim died with the 59× correction, and re-asserting it is the one thing
that would sink the viva.

---

## 8. If someone suggests XGBoost / ML

It is a category error, and you should say so politely:

- **XGBoost forecasts; the LP controls.** They are different layers, not
  competing algorithms for the same job.
- **The LP is exact**, not approximate: the problem is linear and convex, so
  `linprog` returns the global optimum. There is no accuracy to win.
- **Perfect foresight is an upper bound.** The LP already sees the whole
  day. Any forecast error moves the realised cost *up* from Rs 48.97, never
  down. So ML cannot increase the saving; it can only erode it.
- **The margin is smaller than plausible forecast error.** Rs 1.56/day total;
  a 10% load-forecast error in the peak window is worth more than that.

The defensible ML-adjacent extension is not "better model", it is
**value-of-forecast**: run the LP with perfect foresight vs an MPC with a
persistence/XGBoost forecast and report the gap. That is a real contribution,
but the gap will be a fraction of Rs 1.56/day — say so in advance.

More valuable extensions, in order:

1. **Rainflow / depth-aware degradation** — changes the answer from +1.56 to
   +5.81/day and is the actual research gap.
2. **Resilience**: reserve-SOC constraint + outage scenarios. This is where
   a household battery's real value is.
3. **Multi-day / monthly slab horizon** — currently unexercised.

---

## 9. What not to claim

- ~~"Battery cuts the bill by 50%"~~ — cuts the *electricity* bill by 51%;
  net of wear it saves Rs 1.56/day.
- ~~"Phase 3 is 3% better than Phase 2"~~ — it is Rs 1.75/day, and Phase 2
  is itself worse than doing nothing.
- ~~"The battery is not used"~~ — it does 0.68 EFC/day and covers 100% of the
  evening peak; that is the optimum.
- ~~"Optimisation is pointless"~~ — without it, both heuristic controllers
  lose money.
- Never quote the pre-correction wear figures.

---

## 10. Reproduction

```matlab
cd Matlab
startup
run_all_phases          % headline table
run_alpha_sweep         % alpha plateau 0.75-1.07, knee at 1.08
```

Break-even table is produced by sweeping `tariff_params(overrides)` and
`params.N_cycles_rated` through `simulate_day` — see the scratch scripts
used for this note.
