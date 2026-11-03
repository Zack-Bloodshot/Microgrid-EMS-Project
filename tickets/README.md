# Phase 3 Tickets

Implementation tickets for [PHASE3_PLAN.md](../PHASE3_PLAN.md).

Phase 2's solver and legacy degradation model are the comparison baseline.
Phase 3 adds its own DoD-aware degradation model, solver, validator, and driver
under `Matlab/Phase3/`.

## Workflow

1. Pick a ticket whose dependencies are `done`.
2. Set its `status: in-progress`.
3. Implement and run the verification in the ticket.
4. Mark it `done` and record the commit hash under "Completion".
5. Do not mark a ticket done if its acceptance criteria were not actually run.

## Index

| ID | Title | Depends on | Status |
|---|---|---|---|
| [T-001](T-001-dod-degradation-model.md) | Add DoD-aware degradation model | — | done |
| [T-002](T-002-phase3-solver.md) | Implement degradation-aware LP solver | T-001 | done |
| [T-003](T-003-validation.md) | Add Phase 3 validation | T-002 | done |
| [T-004](T-004-pipeline-integration.md) | Integrate Phase 3 into pipeline | T-002, T-003 | done |
| [T-005](T-005-main-phase3.md) | Add `main_phase3` driver and plots | T-004 | done |
| [T-006](T-006-alpha-sweep.md) | Add alpha sweep and trade-off plot | T-002, T-004 | done |
| [T-007](T-007-sunny-cloudy.md) | Extend sunny/cloudy comparison | T-004 | done |
| [T-008](T-008-verification.md) | End-to-end verification script | T-001–T-007 | done |
| [T-009](T-009-docs.md) | Update Phase 3 documentation | T-008 | done |

## Dependency graph

```
T-001 -> T-002 -> T-003 -> T-004 -> T-005
                   |          |  \-> T-007
                   |          \-> T-006
                   \--------------> T-008 -> T-009
```

## Model summary

| Quantity | Value |
|---|---:|
| Rated depth of discharge | 0.80 (SOC 0.10–0.90) |
| Rated cycle life at 80% DoD | 5000 |
| Energy per rated cycle | 16 kWh |
| `c_deg` | Rs 1.6250/kWh throughput |
| Cost per rated cycle | Rs 26.00 |
| Cost per equivalent full cycle | Rs 32.50 |

Phase 2 keeps `A_cycle = 5000`, `b_cycle = 1.3` (legacy 100%-DoD curve). Do
not mix the two models in one table without a label.
