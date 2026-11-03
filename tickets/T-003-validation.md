---
id: T-003
title: Add Phase 3 validation
status: done
depends_on: [T-002]
phase: 3
---

# T-003 — Add Phase 3 validation

## Goal

Provide a Phase 3 validator with the Phase 2 checks plus a terminal-SOC check.
Do not modify `Matlab/Phase2/validate_lp_solution.m`; Phase 2 must stay frozen.

## Files

- `Matlab/Phase3/validate_phase3_solution.m` (new)

## Interface

```matlab
function report = validate_phase3_solution( ...
    P_pv, P_load, P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, params)
```

Mirror the Phase 2 report fields so the downstream print/plot code can treat
Phase 2 and Phase 3 results the same way, and add:

- `report.terminal_soc_ok` — requires `SOC(end) >= params.SOC0 - params.bound_tol`.
- `report.degradation_model` — string, `'DoD 80%, 5000 cycles'` or similar,
  so results are self-documenting.

## Tasks

- Copy the existing Phase 2 checks and tolerances; do not change their meaning.
- Add the terminal-SOC row to `report` and to the overall pass/fail.
- Keep the printed header labelled `Phase 3`.
- Optionally print the degradation-model label.
- Call it from Phase 3 with no extra options.

## Acceptance criteria

- [ ] `main_phase2` still prints the same PASS summary as before.
- [ ] `validate_phase3_solution` prints `Phase 3` and a terminal-SOC line.
- [ ] Forced terminal-SOC violation flips `all_checks_passed` to false.
- [ ] `report` contains the same core fields as the Phase 2 validator.
- [ ] No Phase 2 file is modified.

## Verification

```matlab
cd Matlab
startup
main_phase2
% then, after T-004:
% results = simulate_day(P_pv, P_load, params);
% results.phase3.validation.all_checks_passed
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_phase3` (OVERALL PASS).
