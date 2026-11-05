---
title: Defensibility Analysis
date: 2026-10-15
tags:
  - FYP
  - EMS
  - validation
  - placement
  - sensitivity
status: verified
related:
  - "[[Simulation Results Report]]"
  - "[[System Parameters & Tariff]]"
  - "[[Evidence]]"
---

# Defensibility Analysis

> [!question] The question this answers
> *"If an interviewer attacks my assumptions, which numbers survive — and
> is this thing actually worth building?"*

All figures are sweeps of the production pipeline, reproduced by
`make_defensibility_plots()`.

## TL;DR

| Claim | Verdict |
|-------|---------|
| Optimisation beats a greedy rule by ~14.8–16.5% | **Matches published literature** |
| The *mechanism* (timing, not energy) | **Bulletproof** — arithmetic closes to 4 decimals |
| Battery roughly halves the *electricity bill* | **True, but incomplete** — ignores Rs 130,000 CAPEX |
| Battery is worth its cost on arbitrage alone | **False** — see §6. This is the honest limit. |
| Battery provides backup during outages | **Not modelled at all** — see §7 |

---

## 1. Your Numbers Match Published Literature

![[assets/literature-benchmark.png|760]]

**Sarda et al., *Energy Management System of Microgrid using Optimization
Approach*, IFAC PapersOnLine 55-9 (2022) 280–284** — also a clear-day /
cloudy-day heuristic-vs-optimisation study:

> "The cost comparison of heuristic method is higher for clear day with
> **11.17%** and cloudy day with **14.80%** compared to optimization method."

| | Sarda et al. | This project |
|---|---|---|
| Clear / sunny | 11.17% | **14.80%** |
| Cloudy | 14.80% | **16.48%** |

Your results land **within 3–4 points of an independently published
benchmark, on the correct side, in both weather conditions**, from a
completely different system size, tariff, and dataset. That is the single
strongest thing you can say.

**Say:** *"I validated against Sarda et al., who report 11.17% and 14.80%
for the same comparison. I get 14.8% and 16.5%."* Nobody can argue with
that — you checked against prior art and landed in the same place.

---

## 2. The Mechanism Is Bulletproof

![[assets/soc-timing.png|820]]

Phase 1 and Phase 2 move **identical energy** — 5.433 kWh imported,
2.909 kWh exported, EFC 0.801 each — yet differ by Rs 4.29/day. The
saving reconciles exactly:

```
1.188 kWh × (Rs 8.10 − Rs 5.40) = Rs 3.21   peak → solar shift
0.800 kWh × (Rs 6.75 − Rs 5.40) = Rs 1.08   normal → solar shift
                                   ─────────
                                    Rs 4.29   = observed Rs 4.2872
```

The heuristic buys 1.188 kWh during peak hours; the LP buys **zero**. In
the SOC plot you can see the heuristic hit 0.90 SOC an hour earlier,
then run dry by 21:00 and spike grid import at the worst possible moment.
The LP holds back and still has 0.13 SOC at midnight.

### And your LP is insensitive to the tariff you're defending

| Peak multiplier | Heuristic | **LP** |
|-----------------|-----------|--------|
| 1.0× (Rs 6.75) | Rs 28.05 | **Rs 25.2790** |
| 1.2× (Rs 8.10) | Rs 29.65 | **Rs 25.2790** |
| 2.0× (Rs 13.50) | Rs 36.07 | **Rs 25.2790** |

The LP's cost is **identical to four decimals** across the sweep. Because
it imports zero kWh in peak hours, the peak rate cannot affect it. The
heuristic moves Rs 8.

**Say:** *"Challenge the tariff multiplier as much as you like — my
optimal controller's cost doesn't move, because it never buys power in
the peak window."*

---

## 3. Robust Sweeps

![[assets/sensitivity-gap.png|720]]

The LP-vs-heuristic advantage stays in a narrow band across wide ranges:

| Sweep | Range tested | LP advantage |
|-------|--------------|--------------|
| PV availability | 1.0× → 0.3× | 12.6–16.5% |
| Battery capacity | 5 → 20 kWh | 11.0–14.8% |
| Load scale | 0.85× → 1.3× | 5.3–15.5% |
| Export rate | Rs 0 → 4 | 10.7–14.8% |
| ToD peak mult. | 1.0× → 2.0× | 9.9–23.1% |

**Not a sunny-day artefact.** An 85% cut in solar moves the gain by less
than 4 points. Battery benefit saturates at ~15 kWh — your 10 kWh choice
is near-optimal, not arbitrary (15→20 kWh buys only 4.6 points, because
PV surplus becomes the binding constraint).

**Known limit:** at load 0.85× the gap collapses to 5.3%. With light
load, PV covers so much there is little to schedule. Don't be surprised
if asked.

---

## 4. Two Corrections to My Earlier Analysis

> [!warning] I got these wrong the first time. Both are now fixed.

**1. "The LP sometimes loses to the heuristic" — wrong.**
I reported −53.5% at SOC₀ = 0.8 and concluded the LP could lose. That
was a **division-by-negative artifact**: when the heuristic's cost is
negative (net revenue), dividing the saving by it flips the sign.

Absolute values, which never lie:

| SOC₀ | Heuristic | LP | LP better by |
|------|-----------|----|--------------|
| 0.1 | 29.65 | 25.28 | Rs 4.38 |
| 0.5 | 4.82 | 0.46 | Rs 4.36 |
| 0.8 | −8.02 | −12.30 | Rs 4.29 |

**The LP wins by a near-constant Rs 4.3/day at every starting SOC.** The
absolute gap is stable; only the *percentage* is unstable, because the
denominator collapses toward zero. Stronger claim than I made before.

**2. The degradation model was wrong by ~59×.**
The original formula divided per-timestep throughput by a "cycle life"
derived from *per-timestep* DoD. At a 15-minute timestep DoD is
0.007–0.068, so `DoD^-1.3` resolved to LifeCycles of **1e5–1e6**, making
degradation cost collapse to Rs 0.59/day — effectively zero.

Corrected to throughput costing at the rated depth of discharge
(`c = C_rep / (N_cycles_rated·2·E_B·DoD_rated)`), which is self-consistent by
construction: one rated 80%-DoD cycle costs exactly
`C_rep / N_cycles_rated` (Rs 26.00). See `battery_degradation.m`. **This
changed real conclusions** — see §6.

**Why SOC₀ = 0.1 is the right choice:** at that setting the battery
starts *and ends* the day empty, so no unpriced opening inventory
inflates the result. It is the conservative setting. Verified: all three
phases end at SOC 0.100.

---

## 5. Cost Breakdown

![[assets/cost-breakdown.png|720]]

| Phase | Grid/day | Degradation/day | Total/day |
|-------|----------|-----------------|-----------|
| 0 Baseline | Rs 50.54 | Rs 0.00 | **Rs 50.54** |
| 1 Heuristic | Rs 28.97 | Rs 26.03 | **Rs 55.01** |
| 2 LP naive | Rs 24.69 | Rs 26.03 | **Rs 50.72** |
| 3 LP aware | Rs 26.88 | Rs 22.10 | **Rs 48.97** |

Read this carefully — it is the most important table in your project.

**Under the shared 80%-DoD, 5000-cycle model, the naive battery dispatch does
not pay for itself** (Rs 50.72 vs Rs 50.54/day). It halves the electricity bill,
but the wear cost more than cancels the saving, and the heuristic is clearly
worse (Rs 55.01). Only the degradation-aware Phase 3 controller beats doing
nothing (Rs 48.97).

That is exactly the tension a real FYP should surface: the optimiser is not
worth having unless it adapts to the stricter wear price.

---

## 6. Why Isn't This Built Everywhere? (The Real Answer)

![[assets/breakeven.png|740]]

You asked the right question, and you should ask it *first* in the
interview. Here is the honest arithmetic:

| Quantity | Value |
|----------|-------|
| Battery life (5000 rated cycles × 0.80 DoD ÷ 0.801 EFC/day) | 13.7 years |
| Annual bill saving (LP vs no battery) | Rs 9,436 |
| Annual degradation (shared 80%-DoD model) | Rs 9,502 |
| **Net annual benefit (naive LP)** | **− Rs 66** |
| **Net annual benefit (degradation-aware LP)** | **+ Rs 570** |
| Battery replacement cost | Rs 130,000 |
| **Lifetime bill savings (naive LP)** | **Rs 129,100** |

**Even under the shared 80%-DoD curve, ToD arbitrage does not repay the naive
LP.** The lifetime bill saving of about Rs 129,100 against a Rs 130,000
replacement cost is slightly negative over 13.7 years — roughly −Rs 66/year.
The degradation-aware controller does better because it cycles less: about
+Rs 570/year and Rs 139,100 of lifetime bill savings over 16.1 years. The chart
shows how flat the cumulative savings curve is.

### So why do people install these anyway?

1. **Subsidy.** PM-Surya Ghar gives Rs 1,23,000 for a 3 kW system
   (`Notification-Operational Guidelines.pdf`). Against a Rs 1,30,000
   battery, that is ~95% of CAPEX — net cost Rs 7,000, which pays back
   immediately. **Your project is only viable because it is subsidised.**
   Say this plainly; it shows commercial awareness.
2. **Resilience value — real but unmodelled here.** See §7.
3. **Non-monetary benefits**: power quality, demand-charge avoidance on
   commercial tariffs, ride-through, self-consumption autonomy.
4. **Declining ToD spreads** make arbitrage more valuable over time.

> [!tip] The killer interview line
> *"My own model says ToD arbitrage barely repays the battery — net
> −Rs 66/year for the naive LP and only +Rs 570/year once the controller
> prices wear properly. It works because of the Rs 1,23,000 subsidy, and
> because half the value is backup, which I haven't modelled yet. The
> optimisation layer matters because it makes the battery last longer without
> sacrificing savings."*
>
> That answer is worth more than any savings percentage, because you are
> demonstrating you understand the economics rather than just the control
> algorithm.

---

## 7. Resilience Gap — You're Right, It's Not Modelled

Your instinct is correct. Both controllers are **purely
price-driven**. Neither receives any outage signal, so neither reserves
energy for one.

Trace the heuristic on the sunny day: SOC hits 0.10 at 21:00. A grid
failure at 22:00 leaves you with **0.3 kW of load and an empty battery**.

**This is a known and named limitation, not a hidden flaw.** It is the
standard critique of ToD-only EMS design, and addressing it is exactly
what a stochastic/robust EMS does:

- **Reserve SOC constraint** — enforce `SOC(k) ≥ SOC_reserve` at all
  times, sized to expected outage duration. Simple, and costs little
  (your §3 sweep shows battery benefit saturating well above 10 kWh, so
  a flat reserve is affordable).
- **Outage-scenario EMS** — re-run the LP over a set of stochastic
  outage scenarios rather than one deterministic day.
- **H-infinity / stochastic MPC** — the standard research treatment.

**Say:** *"My EMS is price-driven and holds no outage reserve — if the
grid drops at 22:00 with the heuristic, I'm at 0.1 SOC with no backup.
That's a deliberate scope boundary, and the fix is a reserve SOC
constraint or stochastic MPC, which is my next phase."*

Naming the gap first is much stronger than being caught by it.

---

## 8. Questions You Will Be Asked

**"Your export tariff is made up."**
> "Correct — APDCL publishes no feed-in rate, so Rs 4.00 is a labelled
> assumption. I swept it: at Rs 0 the battery saves 61.5%, at Rs 4 it
> saves 50%, and it only reverses when export is priced at parity with
> import, where round-trip losses make storage pointless."

**"How do you know your numbers aren't inflated?"**
> "I validated against Sarda et al., IFAC 2022 — they report the greedy
> rule costs 11.17% more on clear days and 14.80% more on cloudy days. I
> get 14.80% and 16.48%. Different system, tariff and data, same
> answer."

**"So your LP saves a lot?"**
> "Rs 4.29/day on electricity — about 15%. Modest, and I can show you
> exactly where it comes from: it moves 1.188 kWh out of peak hours."

**"Wouldn't the battery have paid for itself?"**
> "Only just. Under the shared 80%-DoD / 5000-cycle model the naive LP is
> essentially break-even at −Rs 66/year; the degradation-aware controller
> nets about +Rs 570/year because it cycles less. The Rs 1,23,000 subsidy and
> unmodelled backup value are what make it clearly worthwhile. I think that's
> more honest than claiming a battery easily pays for itself."

**"What if the grid cuts out?"**
> "I don't model that — my EMS is price-driven with no outage reserve. The
> heuristic in particular is empty by 21:00. Fix is a reserve SOC
> constraint or stochastic MPC."

**"What's your weakest part?"**
> "Single 24-hour day, so the monthly 300/500 kWh slabs are never reached
> and my monthly figure is a 30× extrapolation. Also my degradation model
> is EFC-based, not rainflow — I found and fixed a 59× error in the
> per-timestep version." Naming a bug you caught yourself is strong.

---

## 9. What NOT to Claim

> [!danger] Overreach risks
> - ~~"Battery cuts the bill by 50%"~~ — true for the *electricity bill
>   only*. With CAPEX and degradation, it doesn't pay back. Always
>   distinguish bill savings from net economics.
> - ~~"LP beats heuristic by 50%"~~ — it's ~15%.
> - ~~"This pays for itself"~~ — it doesn't, on arbitrage alone.
> - ~~"My battery provides backup"~~ — it isn't modelled. Don't imply it.
> - Never quote pre-correction figures (Rs 178.87/month) — those came
>   from hardcoded constants that overwrote real solver output.

---

## 10. Method

Sweeps call the production pipeline unchanged, passing overrides through
`tariff_params(overrides)` → `simulate_day(pv, load, params, tariff)`.
No controller logic was modified. Default output is unchanged by the
override plumbing (verified: Rs 50.54 / 28.97 / 24.69 grid for Phases 0/1/2).

Plots regenerate with `make_defensibility_plots()`.

Related: [[Simulation Results Report]] · [[System Parameters & Tariff]] ·
[[Evidence]] · [[Objectives and Benefits]]