%% MAIN_PHASE1 - Phase 1 Rule-Based EMS: Full 24h Simulation Driver
%
%   Runs the complete Phase 1 pipeline:
%     1) Load system parameters              (system_params)
%     2) Generate deterministic PV profile    (generate_pv_profile)
%     3) Generate deterministic load profile  (generate_load_profile)
%     4) Run the rule-based EMS dispatch      (rule_based_ems)
%     5) Validate the result                  (validate_power_balance)
%     6) Plot PV/load, dispatch, SOC, and curtailment
%
%   This is the single entry point for the Phase 1 baseline simulation.

clear; clc; close all;

% Shared helpers and parameters live one directory above this phase.
phase_dir = fileparts(mfilename('fullpath'));
addpath(fileparts(phase_dir));

%% 1) System parameters
params = system_params();

%% 2) Generate synthetic PV and load profiles
[P_pv, time_vec]   = generate_pv_profile(params);
[P_load, time_vec2] = generate_load_profile(params); % time_vec2 == time_vec

assert(isequal(size(P_pv), size(P_load)), ...
    'main_phase1:dimMismatch', 'P_pv and P_load must have identical dimensions.');
assert(numel(P_pv) == params.N, ...
    'main_phase1:dimMismatch', 'Profile length must equal params.N.');

%% 3) Run the Phase 1 rule-based EMS
[P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt] = rule_based_ems(P_pv, P_load, params);

% Dimension sanity checks before validation/plotting
assert(numel(P_ch)   == params.N,   'P_ch length mismatch.');
assert(numel(P_dis)  == params.N,   'P_dis length mismatch.');
assert(numel(P_gimp) == params.N,   'P_gimp length mismatch.');
assert(numel(P_gexp) == params.N,   'P_gexp length mismatch.');
assert(numel(P_curt) == params.N,   'P_curt length mismatch.');
assert(numel(SOC)    == params.N+1, 'SOC length mismatch (expected N+1).');

%% 4) Validate power balance, SOC bounds, operating limits
report = validate_power_balance(P_pv, P_load, P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, params);

if ~report.all_checks_passed
    warning('main_phase1:validationFailed', ...
        'One or more Phase 1 validation checks failed. See summary above.');
end

%% 5) Plots
% Time axis for SOC (N+1 points, includes t = 24h endpoint)
time_soc = (0:params.N) * params.dt;

figure('Name', 'Phase 1 Rule-Based EMS - 24h Simulation', ...
       'Position', [100, 100, 1000, 850]);

% --- Subplot 1: PV generation vs. Load demand ---
subplot(4,1,1);
plot(time_vec, P_pv, 'LineWidth', 1.6); hold on;
plot(time_vec, P_load, 'LineWidth', 1.6);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('PV Generation vs. Load Demand');
legend('P_{pv}', 'P_{load}', 'Location', 'northwest');

% --- Subplot 2: Dispatch (battery + grid flows) ---
subplot(4,1,2);
plot(time_vec, P_ch,   'LineWidth', 1.4); hold on;
plot(time_vec, -P_dis, 'LineWidth', 1.4);
plot(time_vec, P_gimp, 'LineWidth', 1.4);
plot(time_vec, -P_gexp,'LineWidth', 1.4);
yline(0, 'k-');
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('EMS Dispatch (charge/import positive, discharge/export negative)');
legend('P_{ch}', '-P_{dis}', 'P_{grid,imp}', '-P_{grid,exp}', 'Location', 'northwest');

% --- Subplot 3: Battery SOC trajectory ---
subplot(4,1,3);
plot(time_soc, SOC, 'LineWidth', 1.8); hold on;
yline(params.SOC_min, 'r--');
yline(params.SOC_max, 'r--');
grid on; xlim([0 24]); ylim([0 1]);
xlabel('Time [h]'); ylabel('SOC [-]');
title('Battery State of Charge');
legend('SOC(k)', 'SOC_{min}/SOC_{max}', 'Location', 'northwest');

% --- Subplot 4: PV curtailment ---
subplot(4,1,4);
area(time_vec, P_curt, 'FaceAlpha', 0.5);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('PV Curtailment');

sgtitle('Phase 1: Rule-Based EMS - 24h Deterministic Synthetic-Data Simulation');

%% 6) Console summary of key daily energy totals
E_pv_total    = sum(P_pv)    * params.dt;
E_load_total  = sum(P_load)  * params.dt;
E_ch_total    = sum(P_ch)    * params.dt;
E_dis_total   = sum(P_dis)   * params.dt;
E_gimp_total  = sum(P_gimp)  * params.dt;
E_gexp_total  = sum(P_gexp)  * params.dt;
E_curt_total  = sum(P_curt)  * params.dt;
[total_cost, cost_results] = calculate_costs(...
    P_gimp, P_gexp, params.dt);

fprintf('===== Phase 1 Daily Energy Summary =====\n');
fprintf('PV generated        : %6.2f kWh\n', E_pv_total);
fprintf('Load consumed       : %6.2f kWh\n', E_load_total);
fprintf('Battery charged     : %6.2f kWh\n', E_ch_total);
fprintf('Battery discharged  : %6.2f kWh\n', E_dis_total);
fprintf('Grid imported       : %6.2f kWh\n', E_gimp_total);
fprintf('Grid exported       : %6.2f kWh\n', E_gexp_total);
fprintf('PV curtailed        : %6.2f kWh\n', E_curt_total);
fprintf('Energy cost         : %6.2f Rs\n', cost_results.energy_cost);
fprintf('Export compensation : %6.2f Rs\n', cost_results.export_compensation);
fprintf('Total cost          : %6.2f Rs\n', total_cost);
fprintf('Final SOC           : %6.3f\n', SOC(end));
fprintf('=========================================\n');
