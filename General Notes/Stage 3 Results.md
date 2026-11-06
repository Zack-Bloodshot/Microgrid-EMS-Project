---
title: Stage 3 Results
date: 2026-11-03
tags:
  - FYP
  - EMS
  - stage-3
  - results
  - degradation
  - LP
status: verified
related:
  - "[[Stage 3 (Implementation)]]"
  - "[[STAGE3_PLAN]]"
  - "[[System Parameters & Tariff]]"
  - "[[Simulation Results Report]]"
  - "[[Cloudy vs Sunny Comparison]]"
---

# Stage 3 Results — Degradation-Aware LP EMS

> [!info] Provenance
> Every number in this note is direct console output from
> `run_all_stages()`, `main_stage3()`, `run_alpha_sweep()`, and
> `verify_stage3()` on branch `unify-stage-degradation`, MATLAB R2024b,
> `N = 96` timesteps at `dt = 0.25 h`. Nothing is hand-entered.
>
> **One degradation model for every stage.** Stage 1, Stage 2, and Stage 3
> all use `Matlab/battery_degradation.m`: rated life 5000 cycles at
> `DoD_rated = 0.80`, giving `c_deg = Rs 1.6250/kWh` throughput. Every table
> below is therefore directly comparable; no row is priced on a legacy model.

---

## 1. Degradation Model

The wear cost is linear in energy throughput, evaluated at the design depth
of discharge:

$$
E_{cycled} = \sum_{k=1}^{N}\left(P_{ch}(k)+P_{dis}(k)\right)\Delta t
$$

$$
c_{deg} = \frac{C_{rep}}{N_{cycles,rated}\,2E_B\,DoD_{rated}}
= \frac{130000}{5000 \times 2(10)(0.80)}
= 1.6250\ \text{Rs/kWh}
$$

| Quantity | Value |
|---|---:|
| Design DoD | 0.80 (SOC 0.10–0.90) |
| Rated cycle life at 80% DoD | 5000 cycles |
| Energy per rated cycle | 16 kWh |
| Cost per rated cycle | Rs 26.00 |
| Cost per equivalent full cycle | Rs 32.50 |
| Throughput cost | Rs 1.6250/kWh |

Stage 2 remains a *degradation-unaware controller*: its LP objective is grid
cost only. The same model is applied to its dispatch after the fact, so the
Stage 2 row shows what that dispatch would cost in battery life. Stage 3
feeds the same `c_deg` into its LP objective. The per-timestep DoD and
`LifeCycles` outputs are diagnostics only and are not used for costing.

---

## 2. Headline Result ($\alpha = 1$)

| Quantity | Stage 0 | Stage 1 | Stage 2 | **Stage 3** |
|---|---:|---:|---:|---:|
| Grid cost [Rs/day] | 50.54 | 28.97 | 24.69 | **26.88** |
| Degradation [Rs/day] | 0.00 | 26.03 | 26.03 | **22.10** |
| **Total [Rs/day]** | **50.54** | **55.01** | **50.72** | **48.97** |
| Total [Rs/month, 30 d] | 1516.1 | 1650.2 | 1521.6 | **1469.2** |
| EFC | 0.000 | 0.801 | 0.801 | **0.680** |
| Degradation model | none | 80% DoD, 5000 cyc | 80% DoD, 5000 cyc | **80% DoD, 5000 cyc** |

All four rows are now priced on the same basis. Stage 2 still wins on grid
cost (Rs 24.69), but its wear bill is Rs 26.03/day, so its total
(Rs 50.72) is marginally *above* the no-battery baseline (Rs 50.54). Stage 1
is clearly worse (Rs 55.01).

Stage 3 gives up Rs 2.19/day of grid savings relative to Stage 2 (Rs 26.88 vs
Rs 24.69) but avoids Rs 3.94/day of wear (Rs 22.10 vs Rs 26.03), for a net
gain of **Rs 1.75/day** against the Stage 2 dispatch. Against the no-battery
baseline it saves **Rs 1.56/day**. It does this with fewer equivalent full
cycles (0.801 → 0.680).

> [!warning] Degradation awareness is decisive
> On grid cost alone the naive LP looks best. Once the shared wear model is
> applied to every stage, the ordering changes: no battery Rs 50.54,
> Stage 2 Rs 50.72, Stage 1 Rs 55.01, Stage 3 Rs 48.97. Only the
> degradation-aware controller beats doing nothing.

### Daily energy at $\alpha=1$

| Quantity | Value |
|---|---:|
| PV generated | 15.279 kWh |
| Load consumed | 16.981 kWh |
| Battery charged | 7.147 kWh |
| Battery discharged | 6.450 kWh |
| Grid imported | 6.583 kWh |
| Grid exported | 4.183 kWh |
| PV curtailed | 0.000 kWh |
| Final SOC | 0.100 |

---

## 3. Alpha Sweep

Sweep definition: smallest $\alpha$ where
$EFC \le 0.5 \times EFC(\alpha=0)$.

| $\alpha$ | Grid [Rs/day] | Degradation [Rs/day] | Total [Rs/day] | EFC | Final SOC | Validation |
|---:|---:|---:|---:|---:|---:|---|
| 0.00 | 24.69 | 26.03 | 50.72 | 0.801 | 0.100 | PASS |
| 0.25 | 24.69 | 26.03 | 50.72 | 0.801 | 0.100 | PASS |
| 0.50 | 25.02 | 24.83 | 49.86 | 0.764 | 0.100 | PASS |
| 0.75 | 26.88 | 22.10 | 48.97 | 0.680 | 0.100 | PASS |
| 1.00 | 26.88 | 22.10 | 48.97 | 0.680 | 0.100 | PASS |
| 1.25 | 50.54 | 0.00 | 50.54 | 0.000 | 0.100 | PASS |
| 1.50 | 50.54 | 0.00 | 50.54 | 0.000 | 0.100 | PASS |
| 2.00 | 50.54 | 0.00 | 50.54 | 0.000 | 0.100 | PASS |
| 3.00 | 50.54 | 0.00 | 50.54 | 0.000 | 0.100 | PASS |
| 5.00 | 50.54 | 0.00 | 50.54 | 0.000 | 0.100 | PASS |

**Knee: $\alpha = 1.25$.**

Reading the sweep:

- $\alpha=0$ reproduces Stage 2's dispatch exactly. With the shared wear model
  both the grid cost and the wear cost match Stage 2, so the total is the same
  Rs 50.72/day.
- The plateaus (0–0.25, 0.75–1.0) are expected from an LP: the optimal vertex
  does not change until the penalty crosses a breakpoint.
- $\alpha=1$ keeps the valuable cycling and drops marginal cycling.
- At $\alpha\ge1.25$ the controller idles the battery and the grid cost returns
  to the Stage 0 baseline.
- Total physical cost is lowest in the $\alpha=0.75$–$1.0$ plateau, at
  Rs 48.97/day.

The saved figure is `General Notes/assets/stage3-alpha-sweep.png`.

---

## 4. Cloudy-Day Result

| Quantity | Stage 0 | Stage 1 | Stage 2 | Stage 3 |
|---|---:|---:|---:|---:|
| Grid cost [Rs/day] | 87.14 | 79.47 | 66.37 | 71.78 |
| Degradation [Rs/day] | 0.00 | 14.35 | 24.85 | 14.35 |
| **Total [Rs/day]** | **87.14** | **93.81** | **91.22** | **86.13** |
| EFC | 0.000 | 0.441 | 0.765 | 0.441 |

On the cloudy day the picture is sharper. The naive LP buys the cheapest
electricity (Rs 66.37) but cycles 1.7× harder than the heuristic
(EFC 0.765 vs 0.441), so its wear bill is Rs 24.85/day. Stage 3 keeps the
heuristic's cycling level (EFC 0.441) while improving the timing, landing at
Rs 86.13/day — **Rs 5.09/day below Stage 2** and Rs 1.01/day below the
no-battery baseline. Stage 1's total (Rs 93.81) is worse than doing nothing.

---

## 5. Verification

`verify_stage3` output:

| Check | Result | Detail |
|---|---|---|
| Stage 2 baseline (shared model) | PASS | grid 24.6857, degr 26.0342, EFC 0.8011 |
| All stages share one wear model | PASS | DoD 80%, 5000 cycles |
| Shared degradation constants | PASS | DoD 0.80, 1.6250 Rs/kWh, 26.00 Rs/cycle |
| $\alpha=0$ matches Stage 2 grid cost | PASS | diff `0.00e+00` Rs |
| Terminal SOC $\ge SOC_0$ | PASS | min SOC(end) = 0.1000 |
| Power balance residual | PASS | max 4.44e-16 kW |
| SOC / power / curtailment bounds | PASS | all Stage 3 runs |
| No simultaneous charge/discharge | PASS | all Stage 3 runs |
| Cloudy profile solves and validates | PASS | grid 71.78 Rs, EFC 0.441 |
| Alpha sweep monotonic and valid | PASS | knee $\alpha=1.25$ |
| `total_cost = grid + degradation` | PASS | 48.9738 Rs/day |
| **OVERALL** | **PASS** | |

Reproduce with:

```matlab
cd Matlab
startup
verify_stage3
run_all_stages
main_stage3
run_alpha_sweep
run_comparison
```

---

## 6. Interpretation

1. **One wear model changes the ranking.** On grid cost the naive LP is the
   cheapest controller. Once the same 80%-DoD wear price is applied to every
   dispatch, Stage 1 (Rs 55.01) and Stage 2 (Rs 50.72) both land above the
   no-battery baseline (Rs 50.54). Only Stage 3 (Rs 48.97) is worth having.
2. **Stage 3 finds the economical amount of cycling.** It reduces EFC from
   0.801 to 0.680, giving up Rs 2.19/day of grid savings to avoid Rs 3.94/day
   of wear, for a net gain of Rs 1.75/day against the Stage 2 dispatch.
3. **There is a hard off-switch.** From $\alpha=1.25$ upward the battery stops
   entirely and the total cost jumps to the no-battery baseline of
   Rs 50.54/day.
4. **The headline $\alpha=1$ is not a tuned number.** It is the value where
   wear is priced at its modelled cost. The sweep shows the sensitivity around
   it.
5. **The solver objective is not the bill.** At $\alpha=1$ the solver objective
   is not the physical total because the LP uses linearised ToD import prices
   while the reported bill uses the slab-based `calculate_costs()`. Always
   report `grid_cost` and `deg_cost` separately; their sum is the physical
   total.

---

## 7. Limitations

1. **Single self-contained day.** No multi-day or monthly horizon; monthly
   slabs remain unexercised.
2. **Synthetic profiles.** PV is a shaped cosine and load is a sum of
   Gaussians, not measured data.
3. **Linearised degradation at a rated DoD.** The model prices throughput at
   80% DoD; it does not track each cycle's actual depth. Rainflow counting is
   future work.
4. **5000 cycles at 80% DoD is an assumption.** Plausible for LFP, but not
   taken from a specific datasheet.
5. **Perfect foresight.** The LP sees the whole day; forecast uncertainty and
   MPC are future work.
6. **No temperature or calendar aging.** Only cycling wear is priced.
7. **Alpha is a policy weight.** The sweep is the honest way to present it.

---

## 8. Related Notes

- [[Stage 3 (Implementation)]] — formulation, rationale, and progress-report
  framing
- [[STAGE3_PLAN]] — implementation plan and ticket sequence
- [[Simulation Results Report]] — Stage 0/1/2 baseline
- [[Cloudy vs Sunny Comparison]] — cloudy/sunny comparison
- [[System Parameters & Tariff]] — parameter and tariff sources
