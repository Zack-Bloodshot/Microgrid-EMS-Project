```
[P_gimp, P_gexp, P_curt] = rule_based_ems(P_pv, P_load, params) %Main thing
```
# Inputs:

- $P_{pv}$ (Generated Solar Power at each timestep) 
- $P_{load}$ (Load of the microgrid at each timestep) 

# Constants to be fixed (inputs)

| Parameter                   | Symbol               | Typical range / note                                              |
| --------------------------- | -------------------- | ----------------------------------------------------------------- |
| PV rated power              | $P_{pv,rated}$       | Project-specific — `[INSERT VALUE]`                               |
| Time step                   | $\Delta T$           | 0.25 h (project assumption)                                       |
| Grid import limit           | $P_{grid,imp}^{max}$ | Service-connection dependent — `[INSERT VALUE]`                   |
| Grid export limit           | $P_{grid,exp}^{max}$ | Set by net/EXIM metering agreement — `[INSERT VALUE]`, see Part 8 |

# Outputs 
- $P_{grid-export}$ Power exported to Grid
- $P_{grid-import}$ Power imported from Grid
- $P_{curt}$ Curtailment Tracking (Unused energy) 


# Data taken for first pass
| Parameter         | Value I gave | Meaning                         | Why                                                             |
| ----------------- | -----------: | ------------------------------- | --------------------------------------------------------------- |
| `Ppv_rated`       |     **5 kW** | Maximum rated PV output         | A small, manageable PV system for simulation                    |
| Grid import limit |    **10 kW** | Maximum grid import             | Arbitrary simulation constraint                                 |
| Grid export limit |    **10 kW** | Maximum grid export             | Arbitrary simulation constraint                                 |

### Equations: Phase 0 (No-Storage / Without-Battery Baseline Model)

#### 1. Power Conservation & Balance
* **Net Generation Deficit / Surplus:**
  $$P_{\text{net}}(k) = P_{\text{pv}}(k) - P_{\text{load}}(k)$$

* **Instantaneous Power Balance Conservation:**
  $$P_{\text{pv}}(k) + P_{\text{grid,imp}}(k) = P_{\text{load}}(k) + P_{\text{grid,exp}}(k) + P_{\text{curt}}(k)$$

#### 2. Operational Bounds & System Constraints
* **Grid Connection Limits:**
  $$0 \le P_{\text{grid,imp}}(k) \le P_{\text{grid,imp}}^{\text{max}}$$
  $$0 \le P_{\text{grid,exp}}(k) \le P_{\text{grid,exp}}^{\text{max}}$$

* **Synthetic Data Design Constraint (for feasibility):**
  $$P_{\text{load,max}} \le P_{\text{grid,imp}}^{\text{max}}$$
#### 3. Rule-Based Dispatch Logic (Without Battery)

##### Case A: Solar Surplus ($P_{\text{net}}(k) \ge 0$)
* **Actual Grid Export Power:**
  $$P_{\text{grid,exp}}(k) = \min\left(P_{\text{net}}(k),\, P_{\text{grid,exp}}^{\text{max}}\right)$$

* **Curtailment (if grid export cap is exceeded):**
  $$P_{\text{curt}}(k) = P_{\text{net}}(k) - P_{\text{grid,exp}}(k)$$

* **Inferred Inactive Flows:**
  $$P_{\text{grid,imp}}(k) = 0$$

##### Case B: Solar Deficit ($P_{\text{net}}(k) < 0$)
* **Deficit Power Demand:**
  $$P_{\text{deficit}}(k) = -P_{\text{net}}(k) = P_{\text{load}}(k) - P_{\text{pv}}(k)$$

* **Actual Grid Import Power:**
  $$P_{\text{grid,imp}}(k) = \min\left(P_{\text{deficit}}(k),\, P_{\text{grid,imp}}^{\text{max}}\right)$$

* **Inferred Inactive Flows:**
  $$P_{\text{grid,exp}}(k) = 0, \quad P_{\text{curt}}(k) = 0$$

#### 4. Post-Simulation Validation Check
* **Power Balance Residual:**
  $$\text{Residual}(k) = \left| P_{\text{grid,imp}}(k) - P_{\text{grid,exp}}(k) - P_{\text{load}}(k) + P_{\text{pv}}(k) - P_{\text{curt}}(k) \right| < 10^{-6}$$


---
# Simulation Results 

- Check `system_params.m` , `generate_pv_profile.m` , `generate_load_profile.m` for the data used. 
![](Phase%200.webp)

```
===== Phase 0 EMS Validation Summary =====
Timesteps simulated        : 96
Max power balance residual : 4.441e-16 -> PASS
Grid import within limit   : PASS
Grid export within limit   : PASS
OVERALL RESULT              : PASS
============================================

===== Phase 0 Daily Energy and Cost Summary =====
PV generated        :  15.28 kWh
Load consumed       :  35.29 kWh
Grid imported       :  26.72 kWh
Grid exported       :   6.71 kWh
PV curtailed        :   0.00 kWh
Energy cost         : 192.36 Rs
Export compensation :  26.86 Rs
Total cost          : 165.50 Rs
=================================================
```

---

