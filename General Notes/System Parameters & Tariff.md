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

### Battery Degradation (Phase 2)

| Parameter | Symbol | Value | Unit |
|-----------|--------|-------|------|
| Replacement cost | $C_{rep}$ | 130,000 | Rs |
| Cycle-life coefficient | $A_{cycle}$ | 3000 | — |
| Cycle-life exponent | $b_{cycle}$ | 1.3 | — |

Cycle-life curve: $LifeCycles(DoD) = A_{cycle} \times DoD^{-b_{cycle}}$

### Validation

| Parameter | Value | Unit |
|-----------|-------|------|
| Residual tolerance | $10^{-6}$ | kW |

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

| Monthly Slab | Effective Rate | Full Cost Rate |
|-------------|---------------|----------------|
| 0–300 kWh | Rs 6.75/kWh | Rs 7.74/kWh |
| 300–500 kWh | Rs 6.95/kWh | Rs 7.74/kWh |
| 500+ kWh | Rs 7.74/kWh | Rs 7.74/kWh |

> **Note:** Effective rates are after government subsidies. Full cost rates are the pre-subsidy rates published in the tariff notice.

### Time-of-Day (ToD) Multipliers

| Period | Hours | Multiplier | Effective Rate (Slab 1) |
|--------|-------|-----------|------------------------|
| Solar hours | 09:00–17:00 | 0.80× | Rs 5.40/kWh |
| Peak hours | 17:00–22:00 | 1.80× | Rs 12.15/kWh |
| Normal hours | 22:00–09:00 | 1.00× | Rs 6.75/kWh |

### Export Compensation

| Parameter | Value | Unit |
|-----------|-------|------|
| Export compensation rate | 4.00 | Rs/kWh |
| Net metering | No | — |

> **Note:** The APDCL notice does not publish a feed-in rate. Rs 4.00/kWh is an illustrative value for net-export credit.

### Billing Scale

| Profile | `billing_scale` | Fixed Charge | Use Case |
|---------|----------------|--------------|----------|
| `simulation` | 0.2175 | Rs 70/month | Calibrated household bill |
| `household` | 1.00 | Rs 350/month | Full bill (5 kW × Rs 70/kW) |

> **Note:** `billing_scale` is a calibration multiplier applied to the final cost. It is not a real tariff parameter — it scales the simulated bill to match a representative household. See [[Run All Phases Comparison]] for discussion.

---

## How the Cost Is Calculated

The `calculate_costs()` function applies the tariff in this order:

1. **Slab allocation** — imported energy is assigned chronologically to monthly slabs (0–300, 300–500, 500+)
2. **ToD multipliers** — each timestep's slab rate is multiplied by the ToD factor (0.8× / 1.0× / 1.8×)
3. **Export compensation** — exported energy earns Rs 4.00/kWh
4. **Fixed charge** — Rs 70/month ÷ 30 = Rs 2.33/day
5. **Billing scale** — multiplied by 0.2175 (simulation profile)

### Formula

$$Total = billing\_scale \times \left( \sum_{k=1}^{N} \left[ slab\_rate(k) \times ToD(k) \times P_{imp}(k) \times \Delta t \right] - E_{exp} \times 4.00 + \frac{70}{30} \right)$$

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
| Cloudy | 7.52 kWh |

---

## Related Notes

- [[README]] — full project architecture
- [[Run All Phases Comparison]] — how these parameters drive the all-phase comparison
- [[Cloudy vs Sunny Comparison]] — how PV profile changes affect results
- [[Evidence]] — APDCL tariff source documents
- [[Objectives and Benefits]] — value proposition
