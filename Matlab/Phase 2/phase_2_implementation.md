```matlab
[P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, grid_cost, deg_cost] = lp_naive_ems(P_pv, P_load, tariff, params) % Main function
```

# Inputs:

- $P_{pv}$ (Generated Solar Power at each timestep)
- $P_{load}$ (Load of the microgrid at each timestep)
- $tariff$ (Time-of-Day tariff struct with import price vector $C_{import}$ and export credit vector $C_{export}$)

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
| Grid export limit              | $P_{grid,exp}^{max}$                 | Set by net/EXIM metering agreement — `[INSERT VALUE]`             |
| Battery Replacement Cost       | $Cost_{replacement}$                 | Total cost to replace BESS pack ($)                               |
| Cycle Life Curve Parameters    | $A, b$                               | Power-law fitting parameters ($LifeCycles = A \cdot DoD^{-b}$)    |

# Outputs 
- $P_{ch}$ Power Charged to Battery
- $P_{dis}$ Power Discharged from Battery
- $P_{grid-export}$ Power exported to Grid
- $P_{grid-import}$ Power imported from Grid
- $SOC(k)$ State of charge of battery at each time step
- $P_{curt}$ Curtailment Tracking (Unused excess energy)
- $grid\_cost$ Direct monetary cost paid to the utility under ToD tariffs
- $deg\_cost$ Post-simulation estimated battery degradation cost (unpenalized in solver)

---

# Data taken for first pass

| Parameter          |        Value I gave | Meaning                                   | Why                                          |
| ------------------ | ------------------: | ----------------------------------------- | -------------------------------------------- |
| `Ppv_rated`        |            **5 kW** | Maximum rated PV output                   | A small, manageable PV system for simulation |
| `E_B`              |          **10 kWh** | Battery energy capacity                   | Standard BESS size relative to 5 kW PV       |
| `P_ch_max`         |            **5 kW** | Maximum battery charging power            | 0.5C charge rate                             |
| `P_dis_max`        |            **5 kW** | Maximum battery discharge power           | 0.5C discharge rate                          |
| `SOC0`             |             **0.2** | Initial SOC = 50%                         | Neutral starting point                       |
| `SOC_min`          |             **0.2** | Minimum allowed SOC = 20%                 | Prevents deep discharge                      |
| `SOC_max`          |             **0.9** | Maximum allowed SOC = 90%                 | Battery protection headroom                  |
| `η_ch`             |               **1** | Charging efficiency                       | Round-trip loss modeling                     |
| `η_dis`            |               **1** | Discharging efficiency                    | Round-trip loss modeling                     |
| `Δt`               |          **0.25 h** | 15-minute timestep                        | 96 samples/day                               |
| Grid import limit  |            **4 kW** | Maximum grid import                       | Service limit constraint                     |
| Grid export limit  |            **4 kW** | Maximum grid export                       | Interconnection agreement limit              |
| `Cost_replacement` | **2.5 lakh rupees** | Battery pack replacement cost             | Post-hoc degradation baseline cost           |
| $A, b$ (DoD Curve) |       **3000, 1.3** | $LifeCycles(DoD) = 3000 \cdot DoD^{-1.3}$ | Standard Li-ion battery cycle aging profile  |

---

# Mathematical Optimization Formulation (Linear Programming)

## 1. Decision Variable Vector Layout
For an $N$-step simulation horizon ($N = 96$), the stacked optimization decision vector $x \in \mathbb{R}^{4N}$ is defined as:
$$x = \begin{bmatrix} P_{\text{grid,imp}}(1:N) \\ P_{\text{grid,exp}}(1:N) \\ P_{\text{ch}}(1:N) \\ P_{\text{dis}}(1:N) \end{bmatrix}$$

- $P_{\text{grid,imp}}(k) \ge 0$: Index $1$ to $N$
- $P_{\text{grid,exp}}(k) \ge 0$: Index $N+1$ to $2N$
- $P_{\text{ch}}(k) \ge 0$: Index $2N+1$ to $3N$
- $P_{\text{dis}}(k) \ge 0$: Index $3N+1$ to $4N$

---

## 2. Naive Objective Function (Grid Energy Cost Minimization)
The objective function minimizes total grid energy costs without considering battery health penalties:

$$\min_{x} f^T x = \sum_{k=1}^{N} \left[ C_{\text{import}}(k) \cdot P_{\text{grid,imp}}(k) \cdot \Delta T - C_{\text{export}}(k) \cdot P_{\text{grid,exp}}(k) \cdot \Delta T \right]$$

---

## 3. Power Balance Equality Constraints ($A_{eq} x = b_{eq}$)
At each time step $k \in \{1, \dots, N\}$, instantaneous power balance must hold exactly:

$$P_{\text{grid,imp}}(k) - P_{\text{grid,exp}}(k) + P_{\text{dis}}(k) - P_{\text{ch}}(k) - P_{curt}(k)= P_{\text{load}}(k) - P_{\text{pv}}(k)$$

Matrix mapping for step $k$:
$$A_{eq}(k, k) = 1, \quad A_{eq}(k, N+k) = -1, \quad A_{eq}(k, 2N+k) = -1, \quad A_{eq}(k, 3N+k) = 1$$
$$b_{eq}(k) = P_{\text{load}}(k) - P_{\text{pv}}(k)$$

---

## 4. Discrete-Time Battery Dynamics & Inequality Constraints ($A x \le b$)

### State of Charge Recursion
$$SOC(k) = SOC(0) + \frac{\Delta T}{E_B} \sum_{j=1}^{k} \left( \eta_{\text{ch}} P_{\text{ch}}(j) - \frac{P_{\text{dis}}(j)}{\eta_{\text{dis}}} \right)$$

### SOC Operational Bounds ($SOC_{\text{min}} \le SOC(k) \le SOC_{\text{max}}$)
Using the lower-triangular cumulative-sum matrix operator $L \in \mathbb{R}^{N \times N}$:

1. **Upper Bound Constraint ($SOC(k) \le SOC_{\text{max}}$):**
   $$\frac{\Delta T \cdot \eta_{\text{ch}}}{E_B} \sum_{j=1}^{k} P_{\text{ch}}(j) - \frac{\Delta T}{E_B \cdot \eta_{\text{dis}}} \sum_{j=1}^{k} P_{\text{dis}}(j) \le SOC_{\text{max}} - SOC(0)$$

2. **Lower Bound Constraint ($SOC(k) \ge SOC_{\text{min}} \implies -SOC(k) \le -SOC_{\text{min}}$):**
   $$-\frac{\Delta T \cdot \eta_{\text{ch}}}{E_B} \sum_{j=1}^{k} P_{\text{ch}}(j) + \frac{\Delta T}{E_B \cdot \eta_{\text{dis}}} \sum_{j=1}^{k} P_{\text{dis}}(j) \le SOC(0) - SOC_{\text{min}}$$

---

## 5. Decision Variable Lower & Upper Bounds ($lb \le x \le ub$)

$$0 \le P_{\text{grid,imp}}(k) \le P_{\text{grid,imp}}^{\text{max}}$$
$$0 \le P_{\text{grid,exp}}(k) \le P_{\text{grid,exp}}^{\text{max}}$$
$$0 \le P_{\text{ch}}(k) \le P_{\text{ch,max}}$$
$$0 \le P_{\text{dis}}(k) \le P_{\text{dis,max}}$$

---

# Post-Simulation Battery Degradation Quantification (Post-Hoc Analysis)

Although battery degradation is excluded from the solver decision-making in Phase 2, its financial cost is calculated after simulation completion to prove that naive cost optimization causes excessive degradation:

1. **Energy Throughput & Equivalent Full Cycles (EFC):**
   $$E_{\text{cycled}} = \sum_{k=1}^N \left( P_{\text{ch}}(k) + P_{\text{dis}}(k) \right) \cdot \Delta T$$
   $$\text{EFC} = \frac{E_{\text{cycled}}}{2 \cdot E_B}$$

2. **Depth-of-Discharge (DoD) Stress & Degradation Cost Calculation:**
   $$DoD(k) = \frac{(P_{\text{ch}}(k) + P_{\text{dis}}(k)) \cdot \Delta T}{E_B}$$
   $$LifeCycles(DoD(k)) = A \cdot (DoD(k))^{-b}$$
   $$C_{\text{deg,naive}} = \sum_{k=1}^{N} \left[ Cost_{\text{replacement}} \times \frac{(P_{\text{ch}}(k) + P_{\text{dis}}(k)) \cdot \Delta T}{2 \cdot E_B \cdot LifeCycles(DoD(k))} \right]$$

---

# Post-Simulation Validation Checks

After running `linprog`, the output vectors must pass four sanity checks before being accepted:

1. **Solver Convergence Check:**
   $$\text{exitflag} == 1$$

2. **Power Balance Residual Check:**
   $$\text{Residual}(k) = \left| P_{\text{grid,imp}}(k) - P_{\text{grid,exp}}(k) + P_{\text{dis}}(k)- P_{\text{ch}}(k) - P_{curt}(k) - P_{\text{load}}(k) + P_{\text{pv}}(k) \right| < 10^{-6} \quad \forall k$$

3. **Simultaneous Cycling Absence Check:**
   $$\min\left(P_{\text{ch}}(k),\, P_{\text{dis}}(k)\right) < 10^{-6} \quad \forall k$$

4. **SOC Boundary Enforcement Check:**
   $$SOC_{\text{min}} - 10^{-6} \le SOC(k) \le SOC_{\text{max}} + 10^{-6} \quad \forall k$$


---
