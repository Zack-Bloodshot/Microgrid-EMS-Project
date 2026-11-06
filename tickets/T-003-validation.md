---
id: T-003
title: Add Stage 3 validation
status: done
depends_on: [T-002]
stage: 3
---

# T-003 — Add Stage 3 validation

## Goal

Provide a Stage 3 validator with the Stage 2 checks plus a terminal-SOC check.
Do not modify `Matlab/Stage2/validate_lp_solution.m`; Stage 2 must stay frozen.

## Files

- `Matlab/Stage3/validate_stage3_solution.m` (new)

## Interface

```matlab
function report = validate_stage3_solution( ...
    P_pv, P_load, P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, params)
```

Mirror the Stage 2 report fields so the downstream print/plot code can treat
Stage 2 and Stage 3 results the same way, and add:

- `report.terminal_soc_ok` — requires `SOC(end) >= params.SOC0 - params.bound_tol`.
- `report.degradation_model` — string, `'DoD 80%, 5000 cycles'` or similar,
  so results are self-documenting.

## Tasks

- Copy the existing Stage 2 checks and tolerances; do not change their meaning.
- Add the terminal-SOC row to `report` and to the overall pass/fail.
- Keep the printed header labelled `Stage 3`.
- Optionally print the degradation-model label.
- Call it from Stage 3 with no extra options.

## Acceptance criteria

- [ ] `main_stage2` still prints the same PASS summary as before.
- [ ] `validate_stage3_solution` prints `Stage 3` and a terminal-SOC line.
- [ ] Forced terminal-SOC violation flips `all_checks_passed` to false.
- [ ] `report` contains the same core fields as the Stage 2 validator.
- [ ] No Stage 2 file is modified.

## Verification

```matlab
cd Matlab
startup
main_stage2
% then, after T-004:
% results = simulate_day(P_pv, P_load, params);
% results.stage3.validation.all_checks_passed
```

## Completion

- Commit: pending
- Notes: Implemented and verified with `verify_stage3` (OVERALL PASS).
