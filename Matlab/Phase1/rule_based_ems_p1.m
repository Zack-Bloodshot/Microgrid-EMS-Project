function [P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt] = rule_based_ems_p1(P_pv, P_load, params)
%RULE_BASED_EMS Phase 1 rule-based Energy Management System dispatch.
%
%   [P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt] = RULE_BASED_EMS(P_pv, P_load, params)
%   simulates the greedy rule-based EMS dispatch logic exactly as
%   specified in the project documentation (Section 4: Rule-Based
%   Dispatch Logic), timestep by timestep over the horizon.
%
%   Dispatch priority, per timestep k:
%     Case A - Solar Surplus (P_net(k) >= 0):
%       1) Charge the battery first, bounded by P_ch_max and the
%          available SOC headroom.
%       2) Export any remaining surplus to the grid, bounded by
%          P_grid_exp_max.
%       3) Curtail whatever surplus still remains after export.
%     Case B - Solar Deficit (P_net(k) < 0):
%       1) Discharge the battery first, bounded by P_dis_max and the
%          available SOC headroom.
%       2) Import any remaining deficit from the grid, bounded by
%          P_grid_imp_max.
%
%   Inputs:
%     P_pv    - [1 x N] PV generation at each timestep [kW]
%     P_load  - [1 x N] load demand at each timestep [kW]
%     params  - struct from system_params()
%
%   Outputs:
%     P_ch    - [1 x N] battery charge power [kW]      (>= 0)
%     P_dis   - [1 x N] battery discharge power [kW]    (>= 0)
%     P_gimp  - [1 x N] grid import power [kW]          (>= 0)
%     P_gexp  - [1 x N] grid export power [kW]           (>= 0)
%     SOC     - [1 x N+1] state of charge trajectory, SOC(1) = SOC0
%     P_curt  - [1 x N] curtailed PV power [kW]          (>= 0)
%
%   Note: at any timestep exactly one of {P_ch(k), P_dis(k)} can be
%   nonzero (they are mutually exclusive by construction of the
%   if/else dispatch below), which is checked in validate_power_balance.m.

    N  = params.N;
    dt = params.dt;

    % Unpack battery/grid parameters
    E_B          = params.E_B;
    P_ch_max     = params.P_ch_max;
    P_dis_max    = params.P_dis_max;
    SOC_min      = params.heuristic_SOC_min;
    SOC_max      = params.SOC_max;
    eta_ch       = params.eta_ch;
    eta_dis      = params.eta_dis;
    P_gimp_max   = params.P_grid_imp_max;
    P_gexp_max   = params.P_grid_exp_max;

    % Preallocate outputs
    P_ch   = zeros(1, N);
    P_dis  = zeros(1, N);
    P_gimp = zeros(1, N);
    P_gexp = zeros(1, N);
    P_curt = zeros(1, N);
    SOC    = zeros(1, N + 1);
    SOC(1) = params.SOC0;

    for k = 1:N
        P_net = P_pv(k) - P_load(k);   % Net generation surplus/deficit

        if P_net >= 0
            % ---------- Case A: Solar Surplus ----------

            % Max available charging capacity limited by remaining headroom
            P_ch_headroom = (SOC_max - SOC(k)) * E_B / (eta_ch * dt);
            P_ch_headroom = max(P_ch_headroom, 0); % numerical safety

            P_ch(k) = min([P_net, P_ch_max, P_ch_headroom]);
            P_ch(k) = max(P_ch(k), 0); % numerical safety

            % Remaining surplus after charging
            P_rem_exp = P_net - P_ch(k);

            % Export to grid, bounded by export limit
            P_gexp(k) = min(P_rem_exp, P_gexp_max);
            P_gexp(k) = max(P_gexp(k), 0); % numerical safety

            % Whatever cannot be charged or exported is curtailed
            P_curt(k) = P_rem_exp - P_gexp(k);
            P_curt(k) = max(P_curt(k), 0); % numerical safety

            % Inferred inactive flows
            P_dis(k)  = 0;
            P_gimp(k) = 0;

        else
            % ---------- Case B: Solar Deficit ----------
            P_deficit = -P_net;

            % Max available discharge capacity limited by remaining headroom
            P_dis_headroom = (SOC(k) - SOC_min) * E_B * eta_dis / dt;
            P_dis_headroom = max(P_dis_headroom, 0); % numerical safety

            P_dis(k) = min([P_deficit, P_dis_max, P_dis_headroom]);
            P_dis(k) = max(P_dis(k), 0); % numerical safety

            % Remaining (unmet) deficit after discharging
            P_rem_imp = P_deficit - P_dis(k);

            % Import from grid, bounded by import limit
            P_gimp(k) = min(P_rem_imp, P_gimp_max);
            P_gimp(k) = max(P_gimp(k), 0); % numerical safety

            % Inferred inactive flows
            P_ch(k)   = 0;
            P_gexp(k) = 0;
            P_curt(k) = 0;
        end

        % ---------- Discrete-time battery SOC update ----------
        SOC(k+1) = SOC(k) + (dt / E_B) * (eta_ch * P_ch(k) - P_dis(k) / eta_dis);
    end

end
