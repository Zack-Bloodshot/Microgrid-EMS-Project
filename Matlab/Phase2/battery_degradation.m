function [deg_cost, EFC, DoD, LifeCycles] = battery_degradation(P_ch, P_dis, params)
%BATTERY_DEGRADATION Post-simulation battery degradation quantification.
%
%   [deg_cost, EFC, DoD, LifeCycles] = BATTERY_DEGRADATION(P_ch, P_dis, params)
%   implements the Phase 2 "Post-Simulation Battery Degradation
%   Quantification (Post-Hoc Analysis)" section of
%   phase_2_implementation.md exactly. This cost is NEVER fed back into
%   the LP objective (lp_naive_ems.m) — it exists purely to quantify,
%   after the fact, how much battery degradation the cost-only-naive
%   dispatch caused.
%
%   Equations implemented (documentation Section: Post-Simulation
%   Battery Degradation Quantification):
%
%     E_cycled = sum_k ( P_ch(k) + P_dis(k) ) * dt
%     EFC      = E_cycled / (2 * E_B)
%
%     DoD(k)         = ( P_ch(k) + P_dis(k) ) * dt / E_B
%     LifeCycles(k)  = A * DoD(k)^(-b)
%     C_deg,naive    = sum_k [ Cost_replacement * (P_ch(k)+P_dis(k))*dt
%                               / ( 2 * E_B * LifeCycles(k) ) ]
%
%   Timesteps where DoD(k) = 0 (no cycling activity) contribute zero
%   degradation cost; LifeCycles(k) is undefined (would require 0^-b)
%   and is left as NaN for those steps rather than evaluated.
%
%   Inputs:
%     P_ch, P_dis - [1 x N] battery charge/discharge power [kW]
%     params      - struct from system_params() providing E_B,
%                   Cost_replacement, A_cycle, b_cycle, dt
%
%   Outputs:
%     deg_cost   - scalar, total post-hoc degradation cost [Rs]
%     EFC        - scalar, Equivalent Full Cycles over the horizon
%     DoD        - [1 x N] per-timestep depth-of-discharge stress
%     LifeCycles - [1 x N] per-timestep cycle-life estimate (NaN where
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
    E_cycled = sum(P_ch + P_dis) * dt;
    EFC = E_cycled / (2 * E_B);

    %% Depth-of-Discharge (DoD) stress & degradation cost
    DoD = (P_ch + P_dis) * dt / E_B;

    LifeCycles = nan(1, N);
    deg_cost_k = zeros(1, N);

    active = DoD > 0;
    LifeCycles(active) = A .* DoD(active) .^ (-b);
    deg_cost_k(active) = Cost_replacement .* ...
        ((P_ch(active) + P_dis(active)) * dt) ./ (2 * E_B .* LifeCycles(active));

    deg_cost = sum(deg_cost_k);
end
