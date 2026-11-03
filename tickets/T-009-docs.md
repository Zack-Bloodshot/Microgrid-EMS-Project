---
id: T-009
title: Update Phase 3 documentation
status: done
depends_on: [T-008]
phase: 3
---

# T-009 — Update Phase 3 documentation

## Goal

Make the repository describe **Phase 3** as implemented, with measured numbers
and the DoD-aware degradation model. Phase 2 documentation and results remain
unchanged.

## Files

- `Matlab/Phase3/Phase 3 (Implementation).md`
- `General Notes/Phase 3 Results.md` (new)
- `README.md` (Phase 3 status only)
- `AGENTS.md` (Phase 3 status only)
- `PHASE3_PLAN.md` (status only)

Do **not** edit `General Notes/Simulation Results Report.md`,
`General Notes/Run All Phases Comparison.md`, or any Phase 2 note unless the
user explicitly asks to migrate Phase 2.

## Tasks

### `Matlab/Phase3/Phase 3 (Implementation).md`

- Replace the planned-results section with measured values from
  `verify_phase3`/`run_all_phases`.
- Confirm `c_deg = 1.6250` Rs/kWh, Rs 26.00/rated cycle, Rs 32.50/EFC.
- Record the headline `alpha = 1` dispatch and the alpha sweep.
- Keep the Phase 2 legacy-model comparison clearly labelled.

### `General Notes/Phase 3 Results.md`

Include:

- Provenance: branch, MATLAB version, `N = 96`, `dt = 0.25`.
- DoD-aware model equations and the rated values
  (`DoD_rated = 0.80`, `N_cycles_rated = 5000`).
- Phase 2 legacy vs Phase 2-repriced comparison table.
- Headline `alpha = 1` result.
- Full alpha-sweep table from `run_alpha_sweep`.
- Sunny and cloudy Phase 3 results.
- Which cycling windows survive at `alpha = 1`.
- Limitations: single day, synthetic profiles, linear throughput penalty at a
  rated DoD, 5000-cycle assumption, no rainflow counting.

### `README.md`

- Mark Phase 3 as implemented and point to the solver, driver, plan, and
  results note.
- Keep the existing phases 1–6 architecture description; do not renumber it.

### `AGENTS.md`

- Change "only 0–2 are implemented" to 0–3.
- Add `verify_phase3` to the verification commands.
- Mention that Phase 3 is an LP with a DoD-aware linear throughput penalty, not
  a QP, and that Phase 2 still uses the legacy model.

## Acceptance criteria

- [ ] No Phase 3 doc still says "Phase 3 is future work".
- [ ] Every reported number matches a console run or `verify_phase3` output.
- [ ] The alpha-sweep table includes `alpha = 0` and `alpha = 1`.
- [ ] The results note states the knee definition used.
- [ ] The results note labels which degradation model priced each row.
- [ ] Links from README and AGENTS.md resolve to real files.
- [ ] Phase 2 result notes are untouched.
- [ ] The plan's status line says implemented or superseded.

## Verification

```matlab
cd Matlab
startup
verify_phase3
run_all_phases
run_comparison
```

Cross-check the docs against the printed tables. Do not copy stale figures.

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_phase3` (OVERALL PASS).
