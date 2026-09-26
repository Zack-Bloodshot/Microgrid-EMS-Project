# Comprehensive Project Update Plan: Cost-Optimized Microgrid EMS

## 1. Executive Summary
* **Project Title:** Design & Modelling of a Cost-Optimized Energy Management System (EMS) for a Grid-Tied PV Microgrid.
* **Core Objective:** Formulate and simulate a dynamic, degradation-aware Energy Management System that balances Time-of-Day (ToD) electricity savings against non-linear battery degradation costs.
* **Current Status:**
  * Completed Progress Seminar 1.
  * Clarified regulatory alignment with Assam Power Distribution Company Limited (APDCL) tariffs and Central Financial Assistance (PM-Surya Ghar) guidelines.
  * Re-architected simulation roadmap to include an averaged continuous power-flow model in Simulink alongside MATLAB App Designer.

---

## 2. Regulatory & Commercial Validity

### A. Utility Implementation Evidence (APDCL)
* APDCL actively deploys hybrid rooftop solar microgrids featuring Battery Energy Storage Systems (BESS) for commercial and institutional facilities (e.g., APDCL Tender RfS No. APDCL/CGM (NRE)/NRE-219/2026-27/123).
* Specific reference site: 30 kWp grid-interactive solar setup with a 240 V, 300 Ah battery bank at the Directorate of Land Records and Surveys, Guwahati.

### B. Time-of-Day (ToD) Tariff Spread (FY 2026-27 Order)
APDCL enforces dynamic ToD tariff multipliers across time slots:
* **Solar Hours (09:00 - 17:00 hrs):** 80% of normal energy charges (20% discount).
* **Peak Hours (17:00 - 22:00 hrs):** 120% of normal energy charges (20% surcharge).
* **Normal Hours (22:00 - 09:00 hrs):** 100% of normal energy charges.

### C. Policy Framework (PM-Surya Ghar & Govt. of Assam)
* MNRE PM-Surya Ghar Guidelines (Section 24) explicitly authorize behind-the-meter hybrid inverters and battery storage connections.
* Government of Assam provides up to ₹45,000 in state subsidies on top of ₹78,000 central subsidies for $\ge 3\text{ kW}$ residential systems, significantly lowering upfront solar capital costs and freeing capital for hybrid BESS integration.

---

## 3. Mathematical & Control Architecture

### A. Power Flow & Storage Dynamics
At each discrete time step $k$:

$$\text{Power Balance:} \quad P_{pv}(k) + P_{grid}(k) + P_{batt}(k) = P_{load}(k)$$

$$\text{State of Charge Integration:} \quad E_{batt}(k) = E_{batt}(k-1) - P_{batt}(k) \cdot \Delta T$$

$$\text{Physical Constraints:} \quad SOC_{min} \le SOC(k) \le SOC_{max}, \quad -P_{batt\_rated} \le P_{batt}(k) \le P_{batt\_rated}$$

### B. Multi-Objective Cost Minimization (Phase 3)
Instead of naive arbitrage that rapidly wears out the battery, the EMS minimizes:

$$\min_{x} \sum_{k=1}^{N} \left[ C_{grid}(k) \cdot P_{grid}(k) \cdot \Delta T + \alpha \cdot C_{deg}(P_{batt}(k), SOC(k)) \right]$$

Where $C_{deg}$ incorporates Depth-of-Discharge (DoD) stress functions or Rainflow cycle-counting penalties to protect State of Health ($SoH$).

---

## 4. Implementation Phase & Technical Roadmap
[ PHASE 1 ]
                  Baseline Heuristic Controller
                   (Stateflow / Rule-based Logic)
                                 │
                                 ▼
                             [ PHASE 2 ]
                    Naive Cost Optimization
                (Linear Programming via linprog)
                                 │
                                 ▼
                             [ PHASE 3 ]
                    Degradation-Aware Control
              (Convex Solvers / Metaheuristics: PSO/GA)
                                 │
                                 ▼
                             [ PHASE 4 ]
               Comparative Benchmarking & Trade-off
             (Grid Savings vs. Battery SoH Loss %)
                                 │
                                 ▼
                             [ PHASE 5 ]
                   Model Predictive Control (MPC)
               (Rolling 24-hr Horizon / Smart-Meter Data)
                                 │
                                 ▼
                             [ PHASE 6 ]
                 Full System Integration & GUI
             (Simulink Model + App Designer Dashboard)

---
## 5. Defense Strategy for Evaluation Seminars

### Address Panel Critique: "What Extra Cost Does Solar Save With EMS?"
1. **Unoptimized Solar (Grid-Tied, No Battery):** Exports power during daytime at discounted 80% ToD rates and draws power in the evening at 120% peak rates.
2. **Naive Battery Arbitrage:** Charges/discharges aggressively for minor price shifts, resulting in severe cycle degradation and premature replacement within 2–3 years.
3. **Proposed Degradation-Aware EMS:** Discharges the battery **only** when peak ToD savings exceed the physical cell degradation penalty, maximizing long-term return on investment (ROI) and preserving battery lifespan.

### Address Panel Critique: "To a DISCOM, Is a Battery Just a Load?"
* **Clarification:** A battery is classified as a **Distributed Energy Resource (DER)** / **Energy Storage System (ESS)**, not a passive load.
* **Key Differentiator:** Unidirectional loads cannot feed back into the grid. Bi-directional batteries require certified anti-islanding protection (IEC 62116), EXIM metering, and relay-operated automatic isolation switches to ensure utility line-worker safety and grid synchronization compliance.

---

## 6. Target Deliverables for Progress Seminar 2
* Complete Simulink averaged power-flow model featuring dynamic solar profiles, smart-meter load traces, and APDCL ToD rate switching.
* Implement Rainflow cycle counting / DoD degradation functions in MATLAB scripts.
* Generate comparative time-series plots comparing Phase 1 (Heuristic), Phase 2 (Naive LP), and Phase 3 (Degradation-Aware Optimization).
* Finalize interactive GUI layout in MATLAB App Designer connected to the simulation ba

---
