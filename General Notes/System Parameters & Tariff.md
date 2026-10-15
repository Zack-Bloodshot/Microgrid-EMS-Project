---
title: System Parameters & Tariff Structure
date: 2026-10-04
tags:
  - FYP
  - parameters
  - tariff
  - APDCL
  - battery
  - PV
related:
  - "[[README]]"
  - "[[Run All Phases Comparison]]"
  - "[[Cloudy vs Sunny Comparison]]"
---

# System Parameters & Tariff Structure

## System Parameters (`system_params.m`)

### PV & Grid

| Parameter | Symbol | Value | Unit |
|-----------|--------|-------|------|
| PV rated power | $P_{pv,rated}$ | 3 | kW |
| Max grid import | $P_{imp,max}$ | 5 | kW |
| Max grid export | $P_{exp,max}$ | 5 | kW |

### Simulation Timing

| Parameter | Symbol | Value | Unit |
|-----------|--------|-------|------|
| Time step | $\Delta t$ | 0.25 | h (15 min) |
| Horizon | $T$ | 24 | h |
| Samples | $N$ | 96 | — |

### Battery

| Parameter | Symbol | Value | Unit |
|-----------|--------|-------|------|
| Energy capacity | $E_B$ | 10 | kWh |
| Max charge power | $P_{ch,max}$ | 5 | kW |
| Max discharge power | $P_{dis,max}$ | 5 | kW |
| Initial SOC | $SOC_0$ | 0.10 | — |
| Minimum SOC | $SOC_{min}$ | 0.10 | — |
| Maximum SOC | $SOC_{max}$ | 0.90 | — |
| Charge efficiency | $\eta_{ch}$ | 0.95 | — |
| Discharge efficiency | $\eta_{dis}$ | 0.95 | — |

### Battery Degradation (Phase 1 and Phase 2)

| Parameter | Symbol | Value | Unit |
|-----------|--------|-------|------|
| Replacement cost | $C_{rep}$ | 130,000 | Rs |
| Cycle-life coefficient | $A_{cycle}$ | 3000 | — |
| Cycle-life exponent | $b_{cycle}$ | 1.3 | — |

Cycle-life curve: $LifeCycles(DoD) = A_{cycle} \times DoD^{-b_{cycle}}$

Degradation is reported post-hoc for **both** battery phases. Phase 1
cycles the battery just as heavily as Phase 2, so charging it only to
Phase 2 would understate the heuristic's true cost.

### Validation

| Parameter | Value | Unit |
|-----------|-------|------|
| Residual tolerance (`residual_tol`) | $10^{-6}$ | kW |
| Bound tolerance (`bound_tol`) | $10^{-9}$ | — |

---

## Tariff Structure (`tariff_params.m`)

**Utility:** APDCL (Assam Power Distribution Company Limited)
**Category:** LT-III Domestic-B (5 kW to 30 kW)
**Effective:** 01-Apr-2026

### Fixed Charges

| Parameter | Value | Unit |
|-----------|-------|------|
| Fixed charge | 70.00 | Rs/month/connection |

### Energy Slabs

| Monthly Slab | Effective Rate |
|-------------|---------------|
| 0–300 kWh | Rs 6.75/kWh |
| 300–500 kWh | Rs 6.95/kWh |
| 500+ kWh | Rs 7.74/kWh |

> **Note:** Effective rates are after government subsidies, as published in the APDCL FY2026-27 notice.

### Time-of-Day (ToD) Multipliers

| Period | Hours | Multiplier | Effective Rate (Slab 1) |
|--------|-------|-----------|------------------------|
| Solar hours | 09:00–17:00 | 0.80× | Rs 5.40/kWh |
| Peak hours | 17:00–22:00 | 1.20× | Rs 8.10/kWh |
| Normal hours | 22:00–09:00 | 1.00× | Rs 6.75/kWh |

> **Source:** APDCL FY2026-27 tariff notice — solar hours are billed at 80% of normal energy charges, peak hours at 120%.

### Export Compensation

| Parameter | Value | Unit |
|-----------|-------|------|
| Export compensation rate | 4.00 | Rs/kWh |
| Net metering | No | — |

> **Assumption, not a tariff value.** The APDCL notice publishes no feed-in rate. Rs 4.00/kWh is a project assumption used for scenario comparison and is labelled as such in `tariff_params.m`. It is *not* a sourced figure.

---

## How the Cost Is Calculated

The `calculate_costs()` function applies the tariff in this order:

1. **Slab allocation** — imported energy is assigned chronologically to monthly slabs (0–300, 300–500, 500+)
2. **ToD multipliers** — each timestep's slab rate is multiplied by the ToD factor (0.8× / 1.0× / 1.2×)
3. **Export compensation** — exported energy credited at the assumed Rs 4.00/kWh
4. **Fixed charge** — Rs 70/month ÷ 30 = Rs 2.33/day

### Formula

$$Total = \sum_{k=1}^{N} \left[ slab\_rate(k) \times ToD(k) \times P_{imp}(k) \times \Delta t \right] - E_{exp} \times 4.00 + \frac{70}{30}$$

No calibration or scaling factor is applied to the result. Every figure the project reports is the raw tariff computation.

---

## Load Profile (`generate_load_profile.m`)

The synthetic load profile is a sum of three Gaussians:

| Peak | Time | Amplitude | Sigma |
|------|------|-----------|-------|
| Morning | 08:00 | 0.792 kW | 1.2 h |
| Afternoon | 16:15 | 1.760 kW | 0.75 h |
| Evening | 19:30 | 1.320 kW | 1.5 h |

Base load: 0.264 kW

**Daily energy:** ~16.98 kWh

---

## PV Profile (`generate_pv_profile.m`)

The sunny PV profile is a smooth curve peaking around midday, scaled to the 3 kW rated power. The cloudy profile (`cloudy_profile_1.m`) is a reduced version with the same time vector but lower magnitude.

| Scenario | Daily PV Energy |
|----------|----------------|
| Sunny | 15.28 kWh |
| Cloudy | 6.94 kWh |

---

## Known Limitations

These are properties of the current daily-horizon scope, stated rather
than hidden. None of them are bugs.

1. **Monthly slabs are never exercised.** A representative day imports
   ~13 kWh, so every kWh falls in the first 300 kWh slab. The slab
   allocator is correct but effectively inert at this scale. Crossing the
   300 kWh boundary needs ~23 days of consumption, so a monthly horizon
   is required to make the 2nd and 3rd slabs meaningful.

2. **Monthly figures are extrapolated, not simulated.** "Total/month" is
   30 × the simulated day. Real consumption is seasonal and
   day-to-day variable, so this understates winter bills and overstates
   any day-to-day variance effects.

3. **Fixed charge is pro-rated.** Rs 70/month ÷ 30 approximates a daily
   share. It is a small, flat term and does not affect the comparison
   between phases.

4. **`net_metering` branch is dead code.** `tariff.net_metering` is
   `false`, so the net-metering path in `calculate_costs.m` never runs. It
   is retained for a future tariff scenario, not for the current results.

5. **Terminal SOC is unconstrained in the LP.** Acceptable for a single
   self-contained day whose `SOC0` is a given boundary condition, and no
   exploit is available because PV generation ends at 18:00, leaving no
   late-day energy to bank against the horizon edge. This must be
   revisited if the horizon ever spans multiple days or the PV window
   shifts later into the evening.

6. **PV and load profiles are parametric.** `generate_pv_profile.m` is a
   shaped cosine and `generate_load_profile.m` is a sum of Gaussians,
   scaled to the LT-III Domestic-B band. They are representative, not
   measured. The cloudy case is a stated attenuation of the sunny case.

---

## Related Notes

- [[README]] — full project architecture
- [[Simulation Results Report]] — verified results with hourly dispatch data
- [[Run All Phases Comparison]] — how these parameters drive the all-phase comparison
- [[Cloudy vs Sunny Comparison]] — how PV profile changes affect results
- [[Evidence]] — APDCL tariff source documents
- [[Objectives and Benefits]] — value proposition
