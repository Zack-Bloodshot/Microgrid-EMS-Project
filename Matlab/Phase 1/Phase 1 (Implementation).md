```
[P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt] = rule_based_ems(P_pv, P_load, params) %Main thing
```
# Inputs:

- $P_{pv}$ (Generated Solar Power at each timestep) 
- $P_{load}$ (Load of the microgrid at each timestep) 

# Constants to be fixed (inputs)

| Parameter                      | Symbol                               | Typical range / note                                              |
| ------------------------------ | ------------------------------------ | ----------------------------------------------------------------- |
| PV rated power                 | $P_{pv,rated}$                       | Project-specific — `[INSERT VALUE]`                               |
| Battery energy capacity        | $E_B$                                | kWh — `[INSERT VALUE]`                                            |
| Battery max charge power       | $P_{ch,max}$                         | kW, often $E_B / 2$ for a 0.5C battery                            |
| Battery max discharge power    | $P_{dis,max}$                        | kW                                                                |
| Initial SOC                    | $SOC(0)$                             | Engineering assumption: 0.5 unless otherwise justified            |
| Minimum SOC                    | $SOC_{min}$                          | Engineering assumption: 0.1–0.2 to protect cycle life             |
| Maximum SOC                    | $SOC_{max}$                          | Engineering assumption: 0.9–1.0                                   |
| Charge efficiency              | $\eta_{ch}$                          | Literature-based assumption: 0.95 (Li-ion)                        |
| Discharge efficiency           | $\eta_{dis}$                         | Literature-based assumption: 0.95                                 |
| Time step                      | $\Delta T$                           | 0.25 h (project assumption)                                       |
| Grid import limit              | $P_{grid,imp}^{max}$                 | Service-connection dependent — `[INSERT VALUE]`                   |
| Grid export limit              | $P_{grid,exp}^{max}$                 | Set by net/EXIM metering agreement — `[INSERT VALUE]`, see Part 8 |

# Outputs 
- $P_{ch}$ Power Charged to Battery
- $P_{discharge}$ Power Discharged from Battery
- $P_{grid-export}$ Power exported to Grid
- $P_{grid-import}$ Power imported from Grid
- $SOC(k)$ State of charge of battery at each time step
- $P_{curt}$ Curtailment Tracking (Unused energy) 


# Data taken for first pass
|Parameter|Value I gave|Meaning|Why|
|---|--:|---|---|
|`Ppv_rated`|**5 kW**|Maximum rated PV output|A small, manageable PV system for simulation|
|`E_B`|**10 kWh**|Battery energy capacity|Gives a reasonably sized battery relative to a 5 kW PV system|
|`P_ch_max`|**5 kW**|Maximum battery charging power|Equivalent to a 0.5C charge rate for a 10 kWh battery|
|`P_dis_max`|**5 kW**|Maximum battery discharge power|Same 0.5C assumption|
|`SOC0`|**0.5**|Initial SOC = 50%|Neutral starting point; gives room to both charge and discharge|
|`SOC_min`|**0.2**|Minimum allowed SOC = 20%|Prevents deep discharge|
|`SOC_max`|**0.9**|Maximum allowed SOC = 90%|Leaves headroom instead of charging to 100%|
|`η_ch`|**0.95**|Charging efficiency|Represents charging losses|
|`η_dis`|**0.95**|Discharging efficiency|Represents discharging losses|
|`Δt`|**0.25 h**|15-minute timestep|Your project uses 96 samples/day|
|Grid import limit|**10 kW**|Maximum grid import|Arbitrary simulation constraint|
|Grid export limit|**10 kW**|Maximum grid export|Arbitrary simulation constraint|

# Equations 

## 1. Power Conservation & Balance
* **Net Generation Deficit / Surplus**:
  $$P_{\text{net}}(k) = P_{\text{pv}}(k) - P_{\text{load}}(k)$$

* **Instantaneous Power Balance Conservation**:
  $$P_{\text{pv}}(k) + P_{\text{grid,imp}}(k) + P_{\text{dis}}(k) = P_{\text{load}}(k) + P_{\text{grid,exp}}(k) + P_{\text{ch}}(k) + P_{\text{curt}}(k)$$

## 2. Discrete-Time Battery Dynamics
* **State of Charge (SOC) Recursion Update**:
  $$SOC(k+1) = SOC(k) + \frac{\Delta T}{E_B} \left( \eta_{\text{ch}} P_{\text{ch}}(k) - \frac{P_{\text{dis}}(k)}{\eta_{\text{dis}}} \right)$$
## 3. Operational Bounds & System Constraints
* **Battery State Bounds**:
  $$SOC_{\text{min}} \le SOC(k) \le SOC_{\text{max}}$$

* **Battery Charging / Discharging Rate Limits**:
  $$0 \le P_{\text{ch}}(k) \le P_{\text{ch,max}}$$
  $$0 \le P_{\text{dis}}(k) \le P_{\text{dis,max}}$$

* **Grid Connection Limits**:
  $$0 \le P_{\text{grid,imp}}(k) \le P_{\text{grid,imp}}^{\text{max}}$$
  $$0 \le P_{\text{grid,exp}}(k) \le P_{\text{grid,exp}}^{\text{max}}$$
### Synthetic data design constraint for phase 1  
$$P_{\text{max-load}} \leq P_{max-grid-import}$$
## 4. Rule-Based Dispatch Logic

### Case A: Solar Surplus ($P_{\text{net}}(k) \ge 0$)
* **Max Available Charging Capacity Limit**:
  $$P_{\text{ch,headroom}}(k) = \frac{(SOC_{\text{max}} - SOC(k)) \cdot E_B}{\eta_{\text{ch}} \cdot \Delta T}$$

* **Actual Battery Charge Power**:
  $$P_{\text{ch}}(k) = \min\left(P_{\text{net}}(k),\, P_{\text{ch,max}},\, P_{\text{ch,headroom}}(k)\right)$$

* **Surplus Power Remainder**:
  $$P_{\text{rem,exp}}(k) = P_{\text{net}}(k) - P_{\text{ch}}(k)$$

* **Actual Grid Export Power**:
  $$P_{\text{grid,exp}}(k) = \min\left(P_{\text{rem,exp}}(k),\, P_{\text{grid,exp}}^{\text{max}}\right)$$

* **Curtailment (if grid export cap is exceeded)**:
  $$P_{\text{curt}}(k) = P_{\text{rem,exp}}(k) - P_{\text{grid,exp}}(k)$$

* **Inferred Inactive Flows**:
  $$P_{\text{dis}}(k) = 0, \quad P_{\text{grid,imp}}(k) = 0$$
### Case B: Solar Deficit ($P_{\text{net}}(k) < 0$)
* **Deficit Power Demand**:
  $$P_{\text{deficit}}(k) = -P_{\text{net}}(k) = P_{\text{load}}(k) - P_{\text{pv}}(k)$$

* **Max Available Discharge Capacity Limit**:
  $$P_{\text{dis,headroom}}(k) = \frac{(SOC(k) - SOC_{\text{min}}) \cdot E_B \cdot \eta_{\text{dis}}}{\Delta T}$$

* **Actual Battery Discharge Power**:
  $$P_{\text{dis}}(k) = \min\left(P_{\text{deficit}}(k),\, P_{\text{dis,max}},\, P_{\text{dis,headroom}}(k)\right)$$

* **Unmet Deficit Remainder**:
  $$P_{\text{rem,imp}}(k) = P_{\text{deficit}}(k) - P_{\text{dis}}(k)$$

* **Actual Grid Import Power**:
  $$P_{\text{grid,imp}}(k) = \min\left(P_{\text{rem,imp}}(k),\, P_{\text{grid,imp}}^{\text{max}}\right)$$

* **Inferred Inactive Flows**:
  $$P_{\text{ch}}(k) = 0, \quad P_{\text{grid,exp}}(k) = 0$$
## 5. Post-Simulation Validation Check
* **Power Balance Residual**:
  $$\text{Residual}(k) = \left| P_{\text{grid,imp}}(k) - P_{\text{grid,exp}}(k) + P_{\text{dis}}(k) - P_{\text{ch}}(k) - P_{\text{load}}(k) + P_{\text{pv}}(k) - P_{curt}(k) \right| < 10^{-6}$$

---

# Simulation Results

- Check `system_params.m` , `generate_pv_profile.m` , `generate_load_profile.m` for the data used. 
![[Phase 1.webp|618]]

```

===== Phase 1 EMS Validation Summary =====
Timesteps simulated        : 96
Max power balance residual : 4.441e-16 (tol = 1.0e-06) -> PASS
SOC within [0.10, 0.90]     : PASS
P_ch within [0, 5.0] kW    : PASS
P_dis within [0, 5.0] kW   : PASS
P_gimp within [0, 5.0] kW  : PASS
P_gexp within [0, 5.0] kW  : PASS
No simultaneous ch/dis     : PASS
--------------------------------------------
OVERALL RESULT              : PASS
=============================================

===== Phase 1 Daily Energy Summary =====
PV generated        :  15.28 kWh
Load consumed       :  35.29 kWh
Battery charged     :   6.71 kWh
Battery discharged  :   6.06 kWh
Grid imported       :  20.66 kWh
Grid exported       :   0.00 kWh
PV curtailed        :   0.00 kWh
Energy cost         : 152.30 Rs
Export compensation :   0.00 Rs
Total cost          : 152.30 Rs
Final SOC           :  0.100
=========================================
```

