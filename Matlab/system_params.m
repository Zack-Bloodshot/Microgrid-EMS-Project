function params = system_params()
%SYSTEM_PARAMS Shared system, simulation, and battery parameters.
%
%   Tariff data is provided separately by tariff_params.m.

    %% --- Common PV and grid parameters ---
    params.Ppv_rated      = 3;       % [kW] PV rated power
    params.P_grid_imp_max = 5;      % [kW] Maximum grid import power
    params.P_grid_exp_max = 5;      % [kW] Maximum grid export power

    %% --- Simulation timing ---
    % Horizon is a single self-contained representative day. SOC0 is a
    % boundary condition of that day, not a reset between days.
    params.dt      = 0.25;           % [h] Time step (15 minutes)
    params.T_hours = 24;             % [h] Simulated horizon
    params.N       = round(params.T_hours / params.dt);

    %% --- Battery parameters ---
    params.E_B       = 10;           % [kWh] Battery energy capacity
    params.P_ch_max  = 5;            % [kW] Maximum charge power
    params.P_dis_max = 5;            % [kW] Maximum discharge power
    params.SOC0      = 0.1;          % [-] Initial state of charge
    params.SOC_min   = 0.1;          % [-] Minimum state of charge
    params.SOC_max   = 0.9;          % [-] Maximum state of charge
    params.eta_ch    = 0.95;         % [-] Charging efficiency
    params.eta_dis   = 0.95;         % [-] Discharging efficiency

    %% --- Battery degradation parameters ---
    % One shared model for every phase (battery_degradation.m). Rated life is
    % 5000 cycles at the usable depth-of-discharge window
    % (SOC_max - SOC_min = 0.80), priced as a linear throughput cost:
    %   c_deg = Cost_replacement / (N_cycles_rated * 2 * E_B * DoD_rated)
    params.Cost_replacement = 130000; % [Rs] Total cost to replace the BESS pack
    params.DoD_rated      = params.SOC_max - params.SOC_min; % [-] 0.80
    params.N_cycles_rated = 5000;     % [cycles] rated life at DoD_rated
    params.b_cycle = 1.3;             % [-] LifeCycles diagnostic exponent only

    %% --- Validation tolerances ---
    params.residual_tol = 1e-6;       % [kW] Power-balance tolerance
    params.bound_tol    = 1e-9;       % [-] Slack for SOC and power bound checks
end