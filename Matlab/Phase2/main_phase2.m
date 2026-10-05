%% MAIN_PHASE2 - Phase 2 LP-Based EMS: Full 24h Simulation Driver
%
%   Runs the complete Phase 2 pipeline:
%     1) Load system parameters              (system_params)
%     2) Generate deterministic PV profile    (generate_pv_profile)
%     3) Generate deterministic load profile  (generate_load_profile)
%     4) Load tariff data                     (tariff_params)
%     5) Solve the naive cost-minimizing LP   (lp_naive_ems)
%     6) Validate the result                  (validate_lp_solution)
%     7) Quantify post-hoc degradation        (battery_degradation)
%     8) Plot PV/load, dispatch, SOC, curtailment, and DoD
%
%   This is the single entry point for the Phase 2 LP-based baseline
%   simulation (naive objective: grid cost only, degradation excluded
%   from the solver and evaluated post-hoc for comparison purposes).

clear; clc; close all;

% Shared helpers and parameters live one directory above this phase.
phase_dir = fileparts(mfilename('fullpath'));
addpath(fileparts(phase_dir));

%% 1) System parameters
params = system_params();

%% 2) Generate synthetic PV and load profiles
[P_pv, time_vec]    = generate_pv_profile(params);
[P_load, time_vec2] = generate_load_profile(params); % time_vec2 == time_vec

assert(isequal(size(P_pv), size(P_load)), ...
    'main_phase2:dimMismatch', 'P_pv and P_load must have identical dimensions.');
assert(numel(P_pv) == params.N, ...
    'main_phase2:dimMismatch', 'Profile length must equal params.N.');

%% 3) Tariff data
tariff = tariff_params();

%% 4) Solve the Phase 2 naive LP-based EMS
[P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, grid_cost, deg_cost] = ...
    lp_naive_ems(P_pv, P_load, tariff, params);

% Dimension sanity checks before validation/plotting
assert(numel(P_ch)   == params.N,   'P_ch length mismatch.');
assert(numel(P_dis)  == params.N,   'P_dis length mismatch.');
assert(numel(P_gimp) == params.N,   'P_gimp length mismatch.');
assert(numel(P_gexp) == params.N,   'P_gexp length mismatch.');
assert(numel(P_curt) == params.N,   'P_curt length mismatch.');
assert(numel(SOC)    == params.N+1, 'SOC length mismatch (expected N+1).');

%% 5) Validate power balance, SOC bounds, operating limits
report = validate_lp_solution(P_pv, P_load, P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, params);

if ~report.all_checks_passed
    warning('main_phase2:validationFailed', ...
        'One or more Phase 2 validation checks failed. See summary above.');
end

%% 6) Post-hoc battery degradation metrics (for reporting/plots)
[deg_cost_check, EFC, DoD, LifeCycles] = battery_degradation(P_ch, P_dis, params);
assert(abs(deg_cost_check - deg_cost) < 1e-9, ...
    'main_phase2:degCostMismatch', 'deg_cost from lp_naive_ems and battery_degradation disagree.');

%% 7) Plots
% Time axis for SOC (N+1 points, includes t = 24h endpoint)
time_soc = (0:params.N) * params.dt;

figure('Name', 'Phase 2 LP-Based Naive EMS - 24h Simulation', ...
       'Position', [100, 100, 1000, 950]);

% --- Subplot 1: PV generation vs. Load demand ---
subplot(5,1,1);
plot(time_vec, P_pv, 'LineWidth', 1.6); hold on;
plot(time_vec, P_load, 'LineWidth', 1.6);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('PV Generation vs. Load Demand');
legend('P_{pv}', 'P_{load}', 'Location', 'northwest');

% --- Subplot 2: Dispatch (battery + grid flows) ---
subplot(5,1,2);
plot(time_vec, P_ch,   'LineWidth', 1.4); hold on;
plot(time_vec, -P_dis, 'LineWidth', 1.4);
plot(time_vec, P_gimp, 'LineWidth', 1.4);
plot(time_vec, -P_gexp,'LineWidth', 1.4);
yline(0, 'k-');
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('LP Dispatch (charge/import positive, discharge/export negative)');
legend('P_{ch}', '-P_{dis}', 'P_{grid,imp}', '-P_{grid,exp}', 'Location', 'northwest');

% --- Subplot 3: Battery SOC trajectory ---
subplot(5,1,3);
plot(time_soc, SOC, 'LineWidth', 1.8); hold on;
yline(params.SOC_min, 'r--');
yline(params.SOC_max, 'r--');
grid on; xlim([0 24]); ylim([0 1]);
xlabel('Time [h]'); ylabel('SOC [-]');
title('Battery State of Charge');
legend('SOC(k)', 'SOC_{min}/SOC_{max}', 'Location', 'northwest');

% --- Subplot 4: PV curtailment ---
subplot(5,1,4);
area(time_vec, P_curt, 'FaceAlpha', 0.5);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('PV Curtailment');

% --- Subplot 5: Depth-of-Discharge stress per timestep ---
subplot(5,1,5);
bar(time_vec, DoD, 'BarWidth', 1);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('DoD(k) [-]');
title('Per-Timestep Depth-of-Discharge Stress (post-hoc)');

sgtitle('Phase 2: LP-Based Naive EMS - 24h Cost-Only Optimization');

%% 8) Console summary of key daily energy totals and costs
E_pv_total    = sum(P_pv)    * params.dt;
E_load_total  = sum(P_load)  * params.dt;
E_ch_total    = sum(P_ch)    * params.dt;
E_dis_total   = sum(P_dis)   * params.dt;
E_gimp_total  = sum(P_gimp)  * params.dt;
E_gexp_total  = sum(P_gexp)  * params.dt;
E_curt_total  = sum(P_curt)  * params.dt;

[~, cost_results] = calculate_costs(P_gimp, P_gexp, params.dt);

fprintf('===== Phase 2 Daily Energy & Degradation Summary =====\n');
fprintf('PV generated         : %6.2f kWh\n', E_pv_total);
fprintf('Load consumed        : %6.2f kWh\n', E_load_total);
fprintf('Battery charged      : %6.2f kWh\n', E_ch_total);
fprintf('Battery discharged   : %6.2f kWh\n', E_dis_total);
fprintf('Grid imported        : %6.2f kWh\n', E_gimp_total);
fprintf('Grid exported        : %6.2f kWh\n', E_gexp_total);
fprintf('PV curtailed         : %6.2f kWh\n', E_curt_total);
fprintf('-------------------------------------------------------\n');
fprintf('Energy cost          : %6.2f Rs\n', cost_results.energy_cost);
fprintf('Export compensation  : %6.2f Rs\n', cost_results.export_compensation);
fprintf('Grid cost (net)      : %6.2f Rs\n', grid_cost);
fprintf('Final SOC            : %6.3f\n', SOC(end));
fprintf('-------------------------------------------------------\n');
fprintf('Equivalent Full Cycles (EFC) : %6.3f\n', EFC);
fprintf('Post-hoc degradation cost    : %6.2f Rs\n', deg_cost);
fprintf('=========================================================\n');
