function [deg_cost, EFC, DoD, LifeCycles] = battery_degradation(P_ch, P_dis, params)
%BATTERY_DEGRADATION Unified battery degradation cost used by every stage.
%
%   [deg_cost, EFC, DoD, LifeCycles] = BATTERY_DEGRADATION(P_ch, P_dis, params)
%   prices battery wear from energy throughput using the rated cycle life at
%   the usable depth of discharge. This is the single degradation model for
%   Stage 1, Stage 2, and Stage 3, so their reported wear costs are directly
%   comparable.
%
%   Rated-cycle model:
%
%     DoD_rated       = SOC_max - SOC_min                  (= 0.80)
%     E_cycle_rated   = 2 * E_B * DoD_rated                [kWh/cycle]
%     c_deg           = Cost_replacement / ...
%                       (N_cycles_rated * E_cycle_rated)   [Rs/kWh throughput]
%     C_deg           = c_deg * E_cycled
%
%   where E_cycled = sum_k (P_ch(k) + P_dis(k)) * dt. With the current
%   parameters this gives c_deg = Rs 1.6250/kWh throughput, i.e. Rs 26.00
%   per rated 80%-DoD cycle and Rs 32.50 per equivalent full cycle.
%
%   This is a linear throughput cost: the optimiser never sees a
%   per-timestep DoD. The rated DoD only sets the energy moved by one rated
%   cycle. Stage 2 remains a degradation-unaware controller (its LP
%   objective is grid cost only); this function prices its wear after the
%   fact so all stages can be compared on the same basis. Stage 3 feeds the
%   same c_deg into its LP objective.
%
%   Diagnostics:
%     EFC(k)        = E_cycled / (2 * E_B)  [equivalent 100%-DoD cycles]
%     DoD(k)        = (P_ch(k) + P_dis(k)) * dt / E_B  [per-timestep slice]
%     LifeCycles(k) = N_cycles_rated * (DoD(k)/DoD_rated)^(-b_cycle)
%
%   DoD(k) is a 15-minute energy slice, not the depth of a complete cycle.
%   LifeCycles(k) is therefore a diagnostic only and is NOT used to price
%   wear. Cycle-level depth accounting requires rainflow counting, which is
%   future work.
%
%   Inputs:
%     P_ch, P_dis - [1 x N] battery charge/discharge power [kW]
%     params      - struct from system_params() with dt, E_B,
%                   Cost_replacement, DoD_rated, N_cycles_rated, b_cycle
%
%   Outputs:
%     deg_cost   - scalar total degradation cost [Rs]
%     EFC        - scalar equivalent full cycles over the horizon
%     DoD        - [1 x N] per-timestep throughput slice as a fraction of E_B
%     LifeCycles - [1 x N] diagnostic cycle-life curve (NaN where DoD = 0)

    dt = params.dt;
    E_B = params.E_B;
    Cost_replacement = params.Cost_replacement;
    DoD_rated = params.DoD_rated;
    N_cycles = params.N_cycles_rated;
    b = params.b_cycle;

    P_ch  = P_ch(:).';
    P_dis = P_dis(:).';
    N = numel(P_ch);

    throughput = P_ch + P_dis;
    E_cycled = sum(throughput) * dt;
    EFC = E_cycled / (2 * E_B);

    E_cycle_rated = 2 * E_B * DoD_rated;
    c_deg = Cost_replacement / (N_cycles * E_cycle_rated);
    deg_cost = c_deg * E_cycled;

    DoD = throughput * dt / E_B;
    LifeCycles = nan(1, N);
    active = DoD > 0;
    LifeCycles(active) = N_cycles .* (DoD(active) ./ DoD_rated) .^ (-b);
end
