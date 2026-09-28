# Design & Modelling of a Cost-Optimized EMS for a Grid-Tied PV Microgrid

## Project Architecture Overview
This project models an algorithmic Energy Management System (EMS) designed to perform dynamic Time-of-Day (ToD) tariff cost optimization for a grid-connected solar PV and battery microgrid. The EMS evaluates the trade-off between grid electricity cost savings and long-term battery degradation.

---

## Phase 1: Baseline Heuristic Model (State-Machine Logic)
**Objective:** Establish a baseline operational model using deterministic, rule-based logic without mathematical optimization.

### Key Mechanics
* **Excess PV Generation ($P_{\text{pv}} > P_{\text{load}}$):** Direct surplus solar power to charge the battery ($P_{\text{batt}} < 0$) up to $SOC_{\text{max}}$. Any remaining excess is exported to the grid.
* **Power Deficit ($P_{\text{load}} > P_{\text{pv}}$):** Discharge the battery ($P_{\text{batt}} > 0$) down to $SOC_{\text{min}}$ to meet local demand. Supply any remaining deficit using grid power.
* **Control Implementation:** Implemented via rule-based `if-else` branching or dynamic Stateflow charts.

---

## Phase 2: Cost Optimization Without Battery Cycling Constraints
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

## Phase 3: Cost Optimization With Battery Cycling & Degradation Constraints
**Objective:** Formulate a multi-objective optimization problem that balances ToD tariff grid savings against battery replacement costs.

### Combined Objective Function
$$\min_{x} \sum_{k=1}^{N} \left[ \underbrace{C_{\text{grid}}(k) \cdot P_{\text{grid}}(k) \cdot \Delta T}_{\text{Grid Energy Cost}} + \underbrace{\alpha \cdot C_{\text{deg}}\left(P_{\text{batt}}(k), SOC(k)\right)}_{\text{Battery Degradation Penalty}} \right]$$

* **Degradation Weighting Factor ($\alpha$):** Parameter to scale degradation penalty.
* **Degradation Modeling:** Depth of Discharge (DoD) stress function or non-linear cycle aging curves.

### Optimization Methods
* **Convex / Quadratic Programming:** If degradation is linearized or approximated quadratically.
* **Metaheuristics:** Particle Swarm Optimization (`pso`) or Genetic Algorithm (`ga`) to navigate non-linear battery degradation functions.

---

## Phase 4: Comparative Benchmarking & Sensitivity Analysis
**Objective:** Compare performance across all controllers under standard operational scenarios.

### Comparison Metrics Matrix

| Controller / Scenario | Grid Cost ($) | Degradation Cost ($) | Total Operational Cost ($) | Battery State of Health Loss (%) | Execution Time (s) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **No Storage Baseline** | -- | $0 | -- | 0.0% | N/A |
| **Heuristic (Phase 1)** | -- | -- | -- | Moderate | < 0.1 |
| **Naive Optimization (Phase 2)** | Lowest | Highest | High (Long-term) | Highest | Fast |
| **Degradation-Aware EMS (Phase 3)** | Balanced | Lowest | **Optimal** | Lowest | Moderate |

### Scenario Testing
* **Clear vs. Cloudy Day:** Evaluate stability under sharp solar irradiance fluctuations.
* **Tariff Sensitivity:** Test performance under flat-rate vs. aggressive high-peak ToD structures.

---

## Phase 5: Model Predictive Control (MPC) & Real-Data Validation
**Objective:** Transition from offline full-day optimization to real-time rolling-horizon decision-making.

* **Rolling Horizon Execution:** Re-optimize over a 24-hour prediction horizon at every 15-minute time step using short-term load and solar forecasts.
* **Real-World Trace Validation:** Drive simulations using actual logged campus smart-meter data and regional solar irradiance series.

---

## Phase 6: MATLAB App Designer Dashboard
**Objective:** Build an interactive GUI for final presentation and live demonstration.

* **Interactive Controls:** Sliders for battery capacity, solar array sizing, replacement costs, and ToD price multipliers.
* **Live Visualizations:**
  * Power balance curves ($P_{\text{pv}}$, $P_{\text{load}}$, $P_{\text{grid}}$, $P_{\text{batt}}$).
  * Real-time Battery SOC % tracking.
  * Cumulative grid cost ($) vs. Cumulative battery health loss (%) comparison.

---
