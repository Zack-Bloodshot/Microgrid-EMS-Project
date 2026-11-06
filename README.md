# Design & Modelling of a Cost-Optimized EMS for a Grid-Tied PV Microgrid

## Project Architecture Overview
This project models an algorithmic Energy Management System (EMS) designed to perform dynamic Time-of-Day (ToD) tariff cost optimization for a grid-connected solar PV and battery microgrid. The EMS evaluates the trade-off between grid electricity cost savings and long-term battery degradation.

---

## Stage 1: Baseline Heuristic Model (State-Machine Logic)
**Objective:** Establish a baseline operational model using deterministic, rule-based logic without mathematical optimization.

### Key Mechanics
* **Excess PV Generation ($P_{\text{pv}} > P_{\text{load}}$):** Direct surplus solar power to charge the battery ($P_{\text{batt}} < 0$) up to $SOC_{\text{max}}$. Any remaining excess is exported to the grid.
* **Power Deficit ($P_{\text{load}} > P_{\text{pv}}$):** Discharge the battery ($P_{\text{batt}} > 0$) down to $SOC_{\text{min}}$ to meet local demand. Supply any remaining deficit using grid power.
* **Control Implementation:** Implemented via rule-based `if-else` branching or dynamic Stateflow charts.

---

## Stage 2: Cost Optimization Without Battery Cycling Constraints
**Objective:** Minimize total grid energy cost under dynamic ToD tariffs assuming zero battery degradation cost.

### Mathematical Formulation
$$\min_{x} \sum_{k=1}^{N} C_{\text{grid}}(k) \cdot P_{\text{grid}}(k) \cdot \Delta T$$

$$\text{Subject to: } P_{\text{pv}}(k) + P_{\text{grid}}(k) + P_{\text{batt}}(k) = P_{\text{load}}(k) \quad \forall k$$
$$E_{\text{batt}}(k) = E_{\text{batt}}(k-1) - P_{\text{batt}}(k) \cdot \Delta T$$
$$SOC_{\text{min}} \le SOC(k) \le SOC_{\text{max}}$$
$$-P_{\text{batt-rated}} \le P_{\text{batt}}(k) \le P_{\text{batt-rated}}$$

### Optimization Method
* Solved deterministically using Linear Programming (`linprog` in MATLAB).

### Battery Health Quantification (Post-Simulation Analysis)
To prove that this naive optimization degrades battery health rapidly:
1. Run `linprog` to extract optimal power setpoints $P_{\text{batt-naive}}(k)$.
2. Pass $P_{\text{batt-naive}}(k)$ through a **post-simulation rainflow counting / Depth of Discharge (DoD) degradation model**:
   $$C_{\text{deg-naive}} = \sum_{k=1}^{N} \text{Cost}_{\text{replacement}} \times \left( \frac{\vert{}P_{\text{batt-naive}}(k)\vert{} \cdot \Delta T}{2 \cdot E_{\text{batt-max}} \cdot \text{LifeCycles}(\text{DoD})} \right)$$
3. **Expected Outcome:** High financial savings on grid electricity, but extreme battery wear due to aggressive arbitrage during minor price fluctuations.

---

## Stage 3: Cost Optimization With Battery Cycling & Degradation Constraints
**Status: implemented and verified.** Code lives in `Matlab/Stage3/`; measured
results are in `General Notes/Stage 3 Results.md`.

**Objective:** Formulate a multi-objective optimization problem that balances ToD tariff grid savings against battery replacement costs.

### Combined Objective Function
$$\min_{x} \sum_{k=1}^{N} \left[ \underbrace{C_{\text{grid}}(k) \cdot P_{\text{grid}}(k) \cdot \Delta T}_{\text{Grid Energy Cost}} + \underbrace{\alpha \cdot c_{\text{deg}}\left(P_{\text{ch}}(k)+P_{\text{dis}}(k)\right) \cdot \Delta T}_{\text{Battery Degradation Penalty}} \right]$$

* **Degradation Weighting Factor ($\alpha$):** Dimensionless; $\alpha=1$ prices
  wear at its modelled cost, and an alpha sweep reports the trade-off.
* **Degradation Modeling:** DoD-aware linear throughput cost at the design
  depth of discharge. The battery is rated at **80% DoD and 5000 cycles**:
  $$c_{\text{deg}} = \frac{C_{\text{replacement}}}{N_{\text{cycles,rated}} \cdot 2 E_B \cdot DoD_{\text{rated}}} = \frac{130000}{5000 \times 16} = 1.6250\ \text{Rs/kWh}$$
* **Terminal condition:** $SOC(N+1) \ge SOC_0$, so the optimizer cannot drain
  the battery for free at the horizon edge.

### Optimization Method
* Solved as a **linear program** (`linprog` in MATLAB). The wear term is linear
  in throughput, so the problem stays convex and globally optimal.
* Every stage uses the same DoD-aware model (`Matlab/battery_degradation.m`).
  Stage 2 stays degradation-unaware in its objective but its wear is priced
  with the shared model, so all stage totals are directly comparable.

### Measured Result (sunny day, $\alpha=1$)
| Quantity | Stage 3 |
|---|---:|
| Grid cost | Rs 26.88/day |
| Degradation | Rs 22.10/day |
| **Total** | **Rs 48.97/day** |
| EFC | 0.680 |

The Stage 2 dispatch costs Rs 50.72/day under the same model, so Stage 3
saves Rs 1.75/day by trimming marginal cycling and lands below the
Rs 50.54/day no-battery baseline. The alpha sweep knee is $\alpha=1.25$.

---

## Stage 4: Comparative Benchmarking & Sensitivity Analysis
**Objective:** Compare performance across all controllers under standard operational scenarios.

### Comparison Metrics Matrix

| Controller / Scenario | Grid Cost ($) | Degradation Cost ($) | Total Operational Cost ($) | Battery State of Health Loss (%) | Execution Time (s) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **No Storage Baseline** | -- | $0 | -- | 0.0% | N/A |
| **Heuristic (Stage 1)** | -- | -- | -- | Moderate | < 0.1 |
| **Naive Optimization (Stage 2)** | Lowest | Highest | High (Long-term) | Highest | Fast |
| **Degradation-Aware EMS (Stage 3)** | Balanced | Lowest | **Optimal** | Lowest | Moderate |

### Scenario Testing
* **Clear vs. Cloudy Day:** Evaluate stability under sharp solar irradiance fluctuations.
* **Tariff Sensitivity:** Test performance under flat-rate vs. aggressive high-peak ToD structures.

---

## Stage 5: Model Predictive Control (MPC) & Real-Data Validation
**Objective:** Transition from offline full-day optimization to real-time rolling-horizon decision-making.

* **Rolling Horizon Execution:** Re-optimize over a 24-hour prediction horizon at every 15-minute time step using short-term load and solar forecasts.
* **Real-World Trace Validation:** Drive simulations using actual logged campus smart-meter data and regional solar irradiance series.

---

## Stage 6: MATLAB App Designer Dashboard
**Objective:** Build an interactive GUI for final presentation and live demonstration.

* **Interactive Controls:** Sliders for battery capacity, solar array sizing, replacement costs, and ToD price multipliers.
* **Live Visualizations:**
  * Power balance curves ($P_{\text{pv}}$, $P_{\text{load}}$, $P_{\text{grid}}$, $P_{\text{batt}}$).
  * Real-time Battery SOC % tracking.
  * Cumulative grid cost ($) vs. Cumulative battery health loss (%) comparison.

---
