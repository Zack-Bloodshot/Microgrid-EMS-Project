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
    params.Cost_replacement = 130000; % [Rs] Total cost to replace the BESS pack
    % Cycle-life curve: LifeCycles(DoD) = A_cycle * DoD^(-b_cycle)
    params.A_cycle = 3000;            % [-] Cycle-life curve parameter A
    params.b_cycle = 1.3;             % [-] Cycle-life curve parameter b

    %% --- Validation tolerances ---
    params.residual_tol = 1e-6;       % [kW] Power-balance tolerance
    params.bound_tol    = 1e-9;       % [-] Slack for SOC and power bound checks
end