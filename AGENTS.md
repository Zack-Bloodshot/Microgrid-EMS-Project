# AGENTS.md

MATLAB simulation of a grid-tied PV + battery EMS. No package manager, build
step, or test suite — everything runs from MATLAB (verified on R2024b).

## Running

From `Matlab/` in MATLAB:

- `startup` — adds root plus `Stage0`, `Stage1`, `Stage2`, `Stage3`,
  `Comparison` to the path. Required for ad-hoc function calls.
- `run_all_stages` — runs Stage 0/1/2/3 on the same day, prints the cost/EFC
  table, opens the comparison figure, and saves
  `General Notes/assets/all-stage-cost-comparison.png`.
- `run_comparison` — sunny vs cloudy comparison (calls
  `prepare_cloudy_comparison` then plots).
- `main_stage0`, `main_stage1`, `main_stage2`, `main_stage3` — per-stage
  scripts with plots and daily energy summaries. `main_stage3` saves
  `General Notes/assets/stage3-dispatch-soc.png`.
- `run_alpha_sweep` — Stage 3 cost-vs-wear sweep; saves
  `General Notes/assets/stage3-alpha-sweep.png`.
- `verify_stage3` — end-to-end Stage 3 checks with a PASS/FAIL table.
- `make_defensibility_plots` — regenerates `General Notes/assets/*.png`.

Stage 2 requires the Optimization Toolbox (`linprog`) and raises
`lp_naive_ems:solverFailed` if the solver does not return `exitflag == 1`.
Stage 3 raises `lp_degradation_aware_ems:solverFailed` likewise.

## Verification

- There are no unit tests. Correctness is checked at runtime:
  - Each `main_stageN` calls `validate_*`; inspect `report.all_checks_passed`
    and the printed PASS/FAIL summary.
  - `simulate_day` asserts the Stage 2 and Stage 3 grid and degradation costs
    match an independent recomputation.
  - `verify_stage3` checks Stage 2 regression, that all stages share one wear
    model, alpha-zero equivalence, terminal SOC, bounds, the cloudy case, and
    sweep monotonicity.
- Run `run_all_stages` after changing parameters, dispatch, or cost logic.
  A change is unverified until the validation summary passes.

## Sources of truth

- `Matlab/system_params.m` and `Matlab/tariff_params.m` override any prose.
  Implementation notes contain historical first-pass tables explicitly marked
  superseded (5 kW PV, 1.8x peak, Rs 2.5 lakh battery).
- `General Notes/Simulation Results Report.md` holds the verified, measured
  Stage 0/1/2 results. `General Notes/Stage 3 Results.md` holds the verified
  Stage 3 results.
- `Matlab/battery_degradation.m` is the one degradation model used by every
  stage. It prices throughput at `DoD_rated = 0.80` and
  `N_cycles_rated = 5000`, giving `c_deg = 1.6250 Rs/kWh` throughput
  (Rs 26.00/rated cycle, Rs 32.50/EFC). It is linear in throughput;
  per-timestep `DoD` and `LifeCycles` are diagnostics only and must not be
  used for costing. Older notes showing ~Rs 2/day or a Rs 1.300/kWh legacy
  model are historical (corrected in commits `1b40bd8` and the unification
  branch).
- Stage 2 is degradation-unaware in its LP objective but its dispatch is
  priced with the same model, so all stage totals are directly comparable.
- `video/data.js` calls itself the single source of truth but is stale (1.8x
  peak, Rs 150,000, old costs). Re-derive values from the MATLAB files before
  reusing the video.

## Architecture

- `Matlab/simulate_day.m` is the one shared pipeline; add controllers there
  rather than duplicating wiring in entrypoints.
- Stage 0 = no battery (`rule_based_ems_p0`), Stage 1 = greedy
  (`rule_based_ems_p1`), Stage 2 = LP (`lp_naive_ems`), Stage 3 =
  degradation-aware LP (`lp_degradation_aware_ems`). The README describes
  Stages 1–6; 0–3 are implemented, Stage 4+ is future work.
- `Matlab/battery_degradation.m` lives at the `Matlab/` root and is used by
  Stage 1, Stage 2, and Stage 3. There is no separate legacy model.
- The LP decision vector is `5N`: `[P_gimp; P_gexp; P_ch; P_dis; P_curt]`, each
  `1:N` and nonnegative. SOC bounds use one lower-triangular cumulative-sum
  inequality, not step-by-step constraints. Stage 3 adds one terminal-SOC row.
- PV and load profiles are deterministic synthetic curves, not measured data.
  `cloudy_profile_1` is a stated attenuation of the sunny profile.

## Conventions and gotchas

- Channels are separate nonnegative vectors (`P_ch`, `P_dis`, `P_gimp`,
  `P_gexp`); plots negate discharge/export. Do not introduce a signed `P_batt`.
- Units: kW/kWh, hours (`dt = 0.25`), SOC as a 0–1 fraction, costs in Rs.
- `calculate_costs(P_gimp, P_gexp, dt[, tariff])` applies monthly slabs, then
  ToD multipliers, credits export, and pro-rates the fixed charge by `/30`.
  Omitting `tariff` silently uses the published tariff — pass
  `tariff_params(overrides)` for sensitivity runs.
- Scope is one self-contained day: monthly slabs are never reached, and
  "per month" is 30x the simulated day, not a simulated month. Stage 2 leaves
  terminal SOC unconstrained; Stage 3 requires `SOC(N+1) >= SOC0`.
- The solver objective is not the bill: the LP uses linearised ToD prices while
  `calculate_costs` applies monthly slabs. Report `grid_cost` and `deg_cost`
  separately.

## Repo and tooling

- Work is on `real-simulation`, ~20 commits ahead of `main`; do not use `main`
  as the reference for current results.
- `.docx`, `.pptx`, `/video/`, and `/~` are gitignored. `/~` contains junctions
  into the user home directory — never traverse, edit, or commit it.
- No CI, linter, or formatter config exists. Match the existing MATLAB style
  (function header comments, `%` section banners).
- Video build: `cd video && bash build.sh` (or `--still`). Requires Node,
  ffmpeg, and Playwright hardcoded at `/tmp/opencode/node_modules/playwright`;
  real-time capture takes ~3.5 minutes.
