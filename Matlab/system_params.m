function params = system_params()
%SYSTEM_PARAMS Shared system, simulation, and battery parameters.
%
%   Tariff data is provided separately by tariff_params.m. Battery fields
%   are retained here for Phase 1 and later battery-based phases.

    %% --- Common PV and grid parameters ---
    params.Ppv_rated      = 3;       % [kW] PV rated power
    params.P_grid_imp_max = 5;      % [kW] Maximum grid import power
    params.P_grid_exp_max = 5;      % [kW] Maximum grid export power

    %% --- Simulation timing ---
    params.dt      = 0.25;           % [h] Time step (15 minutes)
    params.T_hours = 24;             % [h] Simulated horizon
    params.N       = round(params.T_hours / params.dt);

    %% --- Phase 1 battery parameters ---
    params.E_B       = 10;           % [kWh] Battery energy capacity
    params.P_ch_max  = 5;            % [kW] Maximum charge power
    params.P_dis_max = 5;            % [kW] Maximum discharge power
    params.SOC0      = 0.1;          % [-] Initial state of charge
    params.SOC_min   = 0.1;          % [-] Minimum state of charge
    params.SOC_max   = 0.9;          % [-] Maximum state of charge
    params.eta_ch    = 0.95;         % [-] Charging efficiency
    params.eta_dis   = 0.95;         % [-] Discharging efficiency

    %% --- Phase 2 battery degradation parameters ---
    % Battery Replacement Cost: total cost to replace the BESS pack.
    params.Cost_replacement = 250000;  % [Rs] (2.5 lakh rupees)
    % Cycle-life curve: LifeCycles(DoD) = A_cycle * DoD^(-b_cycle)
    params.A_cycle = 3000;             % [-] Cycle-life curve parameter A
    params.b_cycle = 1.3;              % [-] Cycle-life curve parameter b


    %% --- Validation ---
    params.residual_tol = 1e-6;      % [kW] Power-balance tolerance
end