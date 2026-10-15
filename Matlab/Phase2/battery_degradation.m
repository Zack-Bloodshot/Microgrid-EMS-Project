function [deg_cost, EFC, DoD, LifeCycles] = battery_degradation(P_ch, P_dis, params)
%BATTERY_DEGRADATION Post-simulation battery degradation quantification.
%
%   [deg_cost, EFC, DoD, LifeCycles] = BATTERY_DEGRADATION(P_ch, P_dis, params)
%   quantifies, after the fact, how much battery degradation the dispatch
%   caused. This cost is NEVER fed back into the LP objective
%   (lp_naive_ems.m) — Phase 2 is deliberately degradation-unaware.
%
%   Equations:
%
%     E_cycled      = sum_k ( P_ch(k) + P_dis(k) ) * dt
%     EFC           = E_cycled / (2 * E_B)
%     c_throughput  = Cost_replacement / (2 * E_B * A_cycle)
%     C_deg         = sum_k c_throughput * ( P_ch(k) + P_dis(k) ) * dt
%
%   Equivalent per full cycle: C_deg = Cost_replacement / A_cycle, since
%   one full cycle moves 2*E_B of throughput. This makes the model
%   self-consistent: the battery incurs exactly one replacement cost
%   spread evenly across A_cycle full cycles.
%
%   DoD(k)         = ( P_ch(k) + P_dis(k) ) * dt / E_B
%   LifeCycles(k)  = A_cycle * DoD(k)^(-b_cycle)
%
%   DoD and LifeCycles are reported as DIAGNOSTICS ONLY. They are not
%   used to weight the cost. The per-timestep DoD is a 15-minute slice of
%   a cycle, not the depth of a complete cycle, so LifeCycles(k) resolves
%   to values of order 1e5-1e6 and is not a meaningful cycle life. Using
%   it to weight cost understates degradation by roughly two orders of
%   magnitude. Cycle-level depth accounting requires rainflow counting,
%   which is future work; until then EFC-based costing is used.
%
%   Timesteps where DoD(k) = 0 contribute zero cost; LifeCycles(k) is
%   undefined there (would require 0^-b) and is left as NaN.
%
%   Inputs:
%     P_ch, P_dis - [1 x N] battery charge/discharge power [kW]
%     params      - struct from system_params() providing E_B,
%                   Cost_replacement, A_cycle, b_cycle, dt
%
%   Outputs:
%     deg_cost   - scalar, total post-hoc degradation cost [Rs]
%     EFC        - scalar, Equivalent Full Cycles over the horizon
%     DoD        - [1 x N] per-timestep throughput as a fraction of E_B
%     LifeCycles - [1 x N] per-timestep LifeCycles diagnostic (NaN where
%                  DoD(k) = 0)

    dt = params.dt;
    E_B = params.E_B;
    A = params.A_cycle;
    b = params.b_cycle;
    Cost_replacement = params.Cost_replacement;

    P_ch  = P_ch(:).';
    P_dis = P_dis(:).';
    N = numel(P_ch);

    %% Energy throughput & Equivalent Full Cycles (EFC)
    throughput = P_ch + P_dis;
    E_cycled = sum(throughput) * dt;
    EFC = E_cycled / (2 * E_B);

    %% Degradation cost: linear in throughput
    c_throughput = Cost_replacement / (2 * E_B * A);
    deg_cost = c_throughput * E_cycled;

    %% Diagnostics (not used in the cost)
    DoD = throughput * dt / E_B;
    LifeCycles = nan(1, N);
    active = DoD > 0;
    LifeCycles(active) = A .* DoD(active) .^ (-b);
end