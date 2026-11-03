---
title: Phase 3 Results
date: 2026-11-03
tags:
  - FYP
  - EMS
  - phase-3
  - results
  - degradation
  - LP
status: verified
related:
  - "[[Phase 3 (Implementation)]]"
  - "[[PHASE3_PLAN]]"
  - "[[System Parameters & Tariff]]"
  - "[[Simulation Results Report]]"
  - "[[Cloudy vs Sunny Comparison]]"
---

# Phase 3 Results — Degradation-Aware LP EMS

> [!info] Provenance
> Every number in this note is direct console output from
> `run_all_phases()`, `main_phase3()`, `run_alpha_sweep()`, and
> `verify_phase3()` on branch `real-simulation`, MATLAB R2024b,
> `N = 96` timesteps at `dt = 0.25 h`. Nothing is hand-entered.
>
> **Both models now use 5000-cycle life.** Phase 2 (and Phase 1) still use the
> legacy 100%-DoD throughput model with `A_cycle = 5000`; Phase 3 uses the
> DoD-aware model with `DoD_rated = 0.80`, `N_cycles_rated = 5000`,
> `c_deg = Rs 1.6250/kWh`. They are still different models, so every table
> labels which one priced each row.

---

## 1. Degradation Model

The Phase 3 wear cost is linear in energy throughput, evaluated at the design
depth of discharge:

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

The legacy Phase 2 model prices throughput at
`130000 / (2 × 10 × 5000) = Rs 1.300/kWh`, i.e. Rs 26.00 per equivalent full
cycle. The per-timestep DoD and `LifeCycles` outputs are diagnostics only and
are not used for costing.

---

## 2. Headline Result ($\alpha = 1$)

| Quantity | Phase 0 | Phase 1 | Phase 2 (legacy) | **Phase 3** |
|---|---:|---:|---:|---:|
| Grid cost [Rs/day] | 50.54 | 28.97 | 24.69 | **26.88** |
| Degradation [Rs/day] | 0.00 | 20.83 | 20.83 | **22.10** |
| **Total [Rs/day]** | **50.54** | **49.80** | **45.51** | **48.97** |
| Total [Rs/month, 30 d] | 1516.1 | 1494.0 | 1365.4 | **1469.2** |
| EFC | 0.000 | 0.801 | 0.801 | **0.680** |
| Degradation model | none | legacy | legacy | **DoD 80%, 5000 cyc** |

Like-for-like comparison: Phase 2's dispatch repriced under the Phase 3 wear
model gives

$$
24.69 + 26.03 = 50.72\ \text{Rs/day}, \qquad EFC = 0.801
$$

Phase 3 therefore saves **Rs 1.74/day** against the same dispatch priced with
the same wear model. It cycles less (EFC 0.801 → 0.680), pays Rs 2.19/day more
for grid energy, and avoids Rs 3.94/day of wear.

> [!warning] The headline table is not like-for-like
> Phase 1 and Phase 2 are priced with the legacy model. Their lower totals
> (Rs 49.80 and Rs 45.51) should not be read as beating Phase 3 (Rs 48.97).
> Under the Phase 3 model the honest comparison is: no battery Rs 50.54,
> repriced Phase 2 dispatch Rs 50.72, Phase 3 Rs 48.97. Phase 3 wins by
> **Rs 1.74/day** over the naive dispatch and **Rs 1.56/day** over doing
> nothing.

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

- $\alpha=0$ reproduces Phase 2's dispatch exactly; the grid-cost difference is
  `0.00e+00`. The wear column is repriced under the Phase 3 model.
- The plateaus (0–0.25, 0.75–1.0) are expected from an LP: the optimal vertex
  does not change until the penalty crosses a breakpoint.
- $\alpha=1$ keeps the valuable cycling and drops marginal cycling.
- At $\alpha\ge1.25$ the controller idles the battery and the grid cost returns
  to the Phase 0 baseline.
- Total physical cost is lowest in the $\alpha=0.75$–$1.0$ plateau, at
  Rs 48.97/day.

The saved figure is `General Notes/assets/phase3-alpha-sweep.png`.

---

## 4. Cloudy-Day Result

| Quantity | Phase 0 | Phase 1 | Phase 2 (legacy) | Phase 3 |
|---|---:|---:|---:|---:|
| Grid cost [Rs/day] | 87.14 | 79.47 | 66.37 | 71.78 |
| Degradation [Rs/day] | 0.00 | 11.48 | 19.88 | 14.35 |
| **Total [Rs/day]** | **87.14** | **90.94** | **86.25** | **86.13** |
| EFC | 0.000 | 0.441 | 0.765 | 0.441 |

Phase 3 beats the no-battery baseline by **Rs 1.01/day** on the cloudy day and
edges out Phase 2 as reported (86.25). It uses the limited PV in the expensive
evening window instead of exporting it cheaply, while keeping wear down.

> [!warning] Model comparison
> Phase 1 and Phase 2 above are priced with the legacy 5000-cycle model. Only
> the Phase 3 row uses the 80%-DoD / 5000-cycle model. Do not compare the
> degradation columns across phases without this caveat.

---

## 5. Verification

`verify_phase3` output:

| Check | Result | Detail |
|---|---|---|
| Phase 2 legacy baseline frozen | PASS | grid 24.6857, degr 20.8274, EFC 0.8011 |
| DoD-aware degradation constants | PASS | DoD 0.80, 1.6250 Rs/kWh, 26.00 Rs/cycle |
| $\alpha=0$ matches Phase 2 grid cost | PASS | diff `0.00e+00` Rs |
| Terminal SOC $\ge SOC_0$ | PASS | min SOC(end) = 0.1000 |
| Power balance residual | PASS | max 4.44e-16 kW |
| SOC / power / curtailment bounds | PASS | all Phase 3 runs |
| No simultaneous charge/discharge | PASS | all Phase 3 runs |
| Cloudy profile solves and validates | PASS | grid 71.78 Rs, EFC 0.441 |
| Alpha sweep monotonic and valid | PASS | knee $\alpha=1.25$ |
| `total_cost = grid + degradation` | PASS | 48.9738 Rs/day |
| **OVERALL** | **PASS** | |

Reproduce with:

```matlab
cd Matlab
startup
verify_phase3
run_all_phases
main_phase3
run_alpha_sweep
run_comparison
```

---

## 6. Interpretation

1. **The two models disagree, and that is the finding.** Under the legacy
   model Phase 2 is Rs 45.51/day, clearly better than the Rs 50.54/day
   no-battery baseline. Repriced under the stricter Phase 3 model the same
   dispatch is Rs 50.72/day, marginally worse than doing nothing. The
   controller is only worth having if it adapts to the stricter wear price.
2. **Phase 3 finds the economical amount of cycling.** It reduces EFC from
   0.801 to 0.680, giving up Rs 2.19/day of grid savings to avoid Rs 3.94/day
   of wear, for a net gain of Rs 1.74/day against the repriced Phase 2
   dispatch. That brings total cost below the no-battery baseline.
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
4. **Mixed degradation models.** Phase 1/2 remain on the legacy 100%-DoD model
   (now also 5000 cycles). Reprice them explicitly when comparing.
5. **5000 cycles at 80% DoD is an assumption.** Plausible for LFP, but not
   taken from a specific datasheet.
6. **Perfect foresight.** The LP sees the whole day; forecast uncertainty and
   MPC are future work.
7. **No temperature or calendar aging.** Only cycling wear is priced.
8. **Alpha is a policy weight.** The sweep is the honest way to present it.

---

## 8. Related Notes

- [[Phase 3 (Implementation)]] — formulation, rationale, and progress-report
  framing
- [[PHASE3_PLAN]] — implementation plan and ticket sequence
- [[Simulation Results Report]] — Phase 0/1/2 baseline
- [[Cloudy vs Sunny Comparison]] — legacy-model cloudy/sunny comparison
- [[System Parameters & Tariff]] — parameter and tariff sources
