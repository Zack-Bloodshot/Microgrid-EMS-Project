---
id: T-009
title: Update Stage 3 documentation
status: done
depends_on: [T-008]
stage: 3
---

# T-009 — Update Stage 3 documentation

## Goal

Make the repository describe **Stage 3** as implemented, with measured numbers
and the DoD-aware degradation model. Stage 2 documentation and results remain
unchanged.

## Files

- `Matlab/Stage3/Stage 3 (Implementation).md`
- `General Notes/Stage 3 Results.md` (new)
- `README.md` (Stage 3 status only)
- `AGENTS.md` (Stage 3 status only)
- `STAGE3_PLAN.md` (status only)

Do **not** edit `General Notes/Simulation Results Report.md`,
`General Notes/Run All Stages Comparison.md`, or any Stage 2 note unless the
user explicitly asks to migrate Stage 2.

## Tasks

### `Matlab/Stage3/Stage 3 (Implementation).md`

- Replace the planned-results section with measured values from
  `verify_stage3`/`run_all_stages`.
- Confirm `c_deg = 1.6250` Rs/kWh, Rs 26.00/rated cycle, Rs 32.50/EFC.
- Record the headline `alpha = 1` dispatch and the alpha sweep.
- Keep the Stage 2 legacy-model comparison clearly labelled.

### `General Notes/Stage 3 Results.md`

Include:

- Provenance: branch, MATLAB version, `N = 96`, `dt = 0.25`.
- DoD-aware model equations and the rated values
  (`DoD_rated = 0.80`, `N_cycles_rated = 5000`).
- Stage 2 legacy vs Stage 2-repriced comparison table.
- Headline `alpha = 1` result.
- Full alpha-sweep table from `run_alpha_sweep`.
- Sunny and cloudy Stage 3 results.
- Which cycling windows survive at `alpha = 1`.
- Limitations: single day, synthetic profiles, linear throughput penalty at a
  rated DoD, 5000-cycle assumption, no rainflow counting.

### `README.md`

- Mark Stage 3 as implemented and point to the solver, driver, plan, and
  results note.
- Keep the existing stages 1–6 architecture description; do not renumber it.

### `AGENTS.md`

- Change "only 0–2 are implemented" to 0–3.
- Add `verify_stage3` to the verification commands.
- Mention that Stage 3 is an LP with a DoD-aware linear throughput penalty, not
  a QP, and that Stage 2 still uses the legacy model.

## Acceptance criteria

- [ ] No Stage 3 doc still says "Stage 3 is future work".
- [ ] Every reported number matches a console run or `verify_stage3` output.
- [ ] The alpha-sweep table includes `alpha = 0` and `alpha = 1`.
- [ ] The results note states the knee definition used.
- [ ] The results note labels which degradation model priced each row.
- [ ] Links from README and AGENTS.md resolve to real files.
- [ ] Stage 2 result notes are untouched.
- [ ] The plan's status line says implemented or superseded.

## Verification

```matlab
cd Matlab
startup
verify_stage3
run_all_stages
run_comparison
```

Cross-check the docs against the printed tables. Do not copy stale figures.

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_stage3` (OVERALL PASS).
