# Stage 3 Plan — Degradation-Aware LP EMS

Status: implemented and verified (MATLAB R2024b, `verify_stage3` PASS).
Owner: FYP.
Scope: add a fourth controller alongside Stage 0/1/2. Stage 2's naive solver and
legacy degradation model act as the comparison baseline; its cycle-life
parameter was updated to 5000 but its results and notes were regenerated
accordingly.

## 1. Goal

Add a degradation-aware dispatch that minimizes

```
grid energy cost + alpha * battery degradation cost
```

over the same 24-hour horizon, then quantify the cost-versus-wear trade-off
with an alpha sweep and compare it against Stage 2.

## 2. Locked modelling decisions

1. **New folder, not a Stage 2 rewrite.** Stage 3 lives in `Matlab/Stage3/`.
   `lp_naive_ems.m` and `battery_degradation.m` stay exactly as they are.
   Stage 3 builds its own constraints and its own degradation model.
2. **DoD-aware degradation model.** Stage 3 rates the battery at its usable
   depth of discharge, `DoD_rated = SOC_max - SOC_min = 0.90 - 0.10 = 0.80`,
   with a rated life of `N_cycles_rated = 5000` cycles. The legacy
   `A_cycle = 5000`, `b_cycle = 1.3` fields remain in `system_params.m` for
   Stage 2, which is now also on 5000 cycles but keeps the 100%-DoD curve.
3. **Linear throughput penalty solved with `linprog`, not a QP proxy.**
   The Stage 3 degradation cost is linear in energy throughput:

   ```
   c_deg = Cost_replacement / (N_cycles_rated * 2 * E_B * DoD_rated)
         = 130000 / (5000 * 2 * 10 * 0.80)
         = Rs 1.6250 per kWh of throughput
         = Rs 26.00 per rated 80%-DoD cycle
         = Rs 32.50 per equivalent full cycle (EFC)
   ```

   Keeping the penalty linear means the optimizer objective and the reported
   degradation metric are the same quantity. A quadratic proxy would optimize
   a different quantity than the one used to report results.
4. **Terminal SOC: `SOC(N+1) >= SOC0`.** Leaving terminal SOC free lets the
   optimizer drain the battery for free, which biases a degradation study.
   A lower bound prevents free energy extraction without forcing an exact
   cyclic endpoint.
5. **Alpha is dimensionless, default `alpha = 1`, plus a sweep.** Both terms are
   in Rs, so `alpha = 1` means "price degradation at its modelled cost".
   The sweep includes values around 1 because the 80%-DoD economics place the
   interesting trade-off near the headline case.
6. **Reported costs stay physical.** The solver objective uses
   `alpha * degradation`; reported `grid_cost`, `degradation_cost`, and
   `total_cost` always use the actual grid bill plus the actual degradation
   cost (`alpha = 1`). Store the raw objective value separately.
7. **Keep the single-day scope.** No monthly horizon, MPC, rainflow counting,
   real-meter data, QP/PSO comparison, or dashboard in this stage.

## 3. Model

Decision vector, unchanged from Stage 2:

```
x = [P_gimp(1:N); P_gexp(1:N); P_ch(1:N); P_dis(1:N); P_curt(1:N)]
```

All entries nonnegative. Objective:

```
min  sum_k [ C_import(k) * P_gimp(k) * dt
           - C_export(k) * P_gexp(k) * dt
           + alpha * c_deg * (P_ch(k) + P_dis(k)) * dt ]
```

where `c_deg = Cost_replacement / (N_cycles_rated * 2 * E_B * DoD_rated)`
= Rs 1.6250 per kWh throughput.

Constraints:

- Power balance at every step, same as `lp_naive_ems.m`.
- SOC recursion and `SOC_min <= SOC(k) <= SOC_max` via the cumulative-sum
  inequality, same as Stage 2.
- Terminal condition:
  `sum_k (eta_ch * P_ch(k) - P_dis(k) / eta_dis) >= 0`.
- Existing bounds on `P_gimp`, `P_gexp`, `P_ch`, `P_dis`, and
  `0 <= P_curt(k) <= P_pv(k)`.

No binary variables. Positive prices and a positive degradation penalty should
keep simultaneous charge/discharge out; the validator still checks it.

### Expected economics

At `alpha = 1`, degradation costs about Rs 3.34 per kWh discharged (throughput
includes both charge and discharge). The battery's arbitrage margin is roughly
Rs 2.5–3.9 per kWh discharged. So:

- normal-window arbitrage is below break-even and should be suppressed;
- peak-window displacement remains marginally profitable and should survive.

Expect EFC below Stage 2's 0.801, with cycling concentrated in the peak window.
The alpha sweep locates the knee where cycling collapses. Do not retune alpha
silently to manufacture a "balanced" schedule.

### Stage 2 comparison under the new model

Stage 2's dispatch model is unchanged (still 100%-DoD), but its cycle-life
parameter is now also 5000. For a like-for-like comparison, its existing
dispatch is re-priced under the Stage 3 model:

| Quantity | Stage 0 | Stage 2, legacy model | Stage 2 dispatch, Stage 3 model |
|---|---:|---:|---:|
| Grid cost | Rs 50.54/day | Rs 24.69/day | Rs 24.69/day |
| Degradation | Rs 0.00/day | Rs 20.83/day | Rs 26.03/day |
| **Total** | **Rs 50.54/day** | **Rs 45.51/day** | **Rs 50.72/day** |
| EFC | 0.000 | 0.801 | 0.801 |

Every table must label which degradation model priced each row.

## 4. Integration points

| File | Change |
|---|---|
| `Matlab/Stage3/battery_degradation_dod.m` (new) | DoD-aware degradation cost. **Done.** |
| `Matlab/Stage3/Stage 3 (Implementation).md` (new) | Equations, solver rationale, validation gates, progress framing. **Done.** |
| `Matlab/system_params.m` | Additive Stage 3 fields (`DoD_rated`, `N_cycles_rated`). **Done.** |
| `Matlab/Stage3/lp_degradation_aware_ems.m` (new) | Stage 3 solver, returns the same trajectory fields plus `objective_value`. |
| `Matlab/Stage3/validate_stage3_solution.m` (new) | Stage 3 validator with terminal-SOC check. Stage 2 validator untouched. |
| `Matlab/simulate_day.m` | Accept optional `alpha`; add `results.stage3`. |
| `Matlab/run_all_stages.m` | Four-stage table and stacked cost chart. |
| `Matlab/Stage3/main_stage3.m` (new) | Standalone driver, plots, and summary. |
| `Matlab/Stage3/run_alpha_sweep.m` (new) | Solve for a vector of alpha values and plot the trade-off. |
| `Matlab/Comparison/prepare_cloudy_comparison.m` | Include `stage3` in cost and energy summaries. |
| `Matlab/Comparison/plot_comparison.m` | Add Stage 3 to cost bars and daily-detail panels. |
| `Matlab/Stage3/verify_stage3.m` (new) | Repeatable end-to-end assertions (no MATLAB unit-test framework in repo). |
| `Matlab/Stage3/Stage 3 (Implementation).md` | Update with measured results after verification. |
| `README.md`, `AGENTS.md` | Document the implemented stage and the Stage 3 degradation model. |

`simulate_day` signature becomes
`simulate_day(P_pv, P_load, params, tariff, alpha)` with `alpha = 1` when
omitted. Existing four-argument callers keep working.

**Stage 2 files must not be modified:** `Matlab/Stage2/lp_naive_ems.m`,
`Matlab/Stage2/battery_degradation.m`, `Matlab/Stage2/validate_lp_solution.m`,
and any Stage 2 result notes.

## 5. Ticket sequence

| ID | Ticket | Depends on | Outcome |
|---|---|---|---|
| T-001 | Add DoD-aware degradation model | — | `battery_degradation_dod.m` plus Stage 3 params; Stage 2 untouched. |
| T-002 | Implement Stage 3 solver | T-001 | Degradation-aware dispatch with terminal SOC. |
| T-003 | Add Stage 3 validation | T-002 | Stage 3 validated, terminal SOC checked; Stage 2 validator untouched. |
| T-004 | Integrate into `simulate_day` / `run_all_stages` | T-002, T-003 | Four-stage pipeline and comparison table. |
| T-005 | Add `main_stage3` driver and plots | T-004 | Standalone Stage 3 run with dispatch/SOC/cost figures. |
| T-006 | Add alpha sweep | T-002, T-004 | Trade-off table and plot; knee identified. |
| T-007 | Extend sunny/cloudy comparison | T-004 | Stage 3 included in both scenarios and plots. |
| T-008 | End-to-end verification | T-001–T-007 | `verify_stage3.m` passes; results captured. |
| T-009 | Update documentation | T-008 | Stage 3 note and README/AGENTS match measured output. |

## 6. Verification gates

A ticket is not done until the relevant gates below pass.

1. **Stage 2 baseline updated:** its sunny-day grid cost `Rs 24.6857`,
   degradation `Rs 20.83`, and EFC `0.801` are the current 5000-cycle values.
   Do not mix them with the Stage 3 model.
2. **Degradation model:** `battery_degradation_dod` returns
   `c_deg = Rs 1.6250/kWh`, `Rs 26.00/rated cycle`, `Rs 32.50/EFC` for the
   current parameters.
3. **`alpha = 0` equivalence:** Stage 3 with `alpha = 0` matches Stage 2's
   sunny-day **grid cost** within `1e-6` Rs. Degradation is not expected to
   match, because the models differ.
4. **Terminal SOC:** `SOC(N+1) >= SOC0 - 1e-9` for every Stage 3 run.
5. **Power balance:** max residual below `params.residual_tol` for sunny and
   cloudy.
6. **Operating limits:** SOC, charge/discharge, import/export, and curtailment
   bounds pass; no simultaneous charge/discharge.
7. **Cost cross-checks:** solver `grid_cost` matches `calculate_costs()` and
   solver `deg_cost` matches `battery_degradation_dod()`.
8. **Sweep sanity:** increasing alpha does not increase EFC or degradation
   cost, and does not decrease grid cost. Flat regions are allowed.
9. **Cloudy case:** Stage 3 solves and validates on `cloudy_profile_1`.
10. **Docs provenance:** every number in the results note is copied from a
    console run or `verify_stage3`, not hand-entered.

## 7. Measured outcomes

Sunny day, `alpha = 1`:

| Quantity | Stage 0 | Stage 1 | Stage 2 (legacy) | Stage 3 |
|---|---:|---:|---:|---:|
| Grid [Rs/day] | 50.54 | 28.97 | 24.69 | 26.88 |
| Degradation [Rs/day] | 0.00 | 20.83 | 20.83 | 22.10 |
| Total [Rs/day] | 50.54 | 49.80 | 45.51 | 48.97 |
| EFC | 0.000 | 0.801 | 0.801 | 0.680 |

- Stage 2 dispatch repriced under the Stage 3 model: Rs 50.72/day, EFC 0.801.
- Stage 3 therefore saves Rs 1.74/day against the same dispatch under the same
  wear model, and lands below the Rs 50.54/day no-battery baseline.
- Alpha sweep knee: `alpha = 1.25` (battery idles above this).
- Cloudy day Stage 3: total Rs 86.13/day, EFC 0.441.
- `verify_stage3`: OVERALL PASS (10/10 checks).
- Full record: `General Notes/Stage 3 Results.md`.

## 8. Out of scope

- Changing Stage 2 code, results, or notes.
- Quadratic `quadprog` proxy, PSO/GA, or solver benchmarking.
- Rainflow counting or cycle-level degradation accounting.
- Multi-day/monthly horizon, forecast uncertainty, MPC, or real-meter data.
- GUI/dashboard, report/PPT regeneration, or video changes.

## 9. Deferred decisions

- Migrating Stage 2 to the DoD-aware model (separate change, after Stage 3).
- Adding Stage 3 to the default `run_all_stages` output (makes the existing
  three-stage table four-stage).
