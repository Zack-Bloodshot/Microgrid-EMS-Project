%% MAIN_PHASE0 - Phase 0 no-storage PV/grid baseline simulation
%
%   Runs the complete Phase 0 pipeline: parameter loading, deterministic
%   profile generation, no-storage dispatch, validation, plotting, and
%   daily import/export cost calculation.

clear; clc; close all;

% Shared helpers and parameters live one directory above this phase.
phase_dir = fileparts(mfilename('fullpath'));
addpath(fileparts(phase_dir));

%% 1) System parameters and synthetic profiles
params = system_params();
[P_pv, time_vec] = generate_pv_profile(params);
[P_load, time_vec2] = generate_load_profile(params);
assert(isequal(time_vec, time_vec2), 'Time vectors must match.');
assert(isequal(size(P_pv), size(P_load)), ...
    'main_phase0:dimMismatch', 'P_pv and P_load must have identical dimensions.');

%% 2) Run the Phase 0 no-storage EMS
[P_gimp, P_gexp, P_curt] = rule_based_ems(P_pv, P_load, params);

%% 3) Validate balance and operating limits
report = validate_power_balance(P_pv, P_load, P_gimp, P_gexp, P_curt, params);
if ~report.all_checks_passed
    warning('main_phase0:validationFailed', ...
        'One or more Phase 0 validation checks failed.');
end

%% 4) Plot profiles and grid dispatch
figure('Name', 'Phase 0 No-Storage EMS - 24h Simulation', ...
    'Position', [100, 100, 1000, 700]);

subplot(3,1,1);
plot(time_vec, P_pv, 'LineWidth', 1.6); hold on;
plot(time_vec, P_load, 'LineWidth', 1.6);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('PV Generation vs. Load Demand');
legend('P_{pv}', 'P_{load}', 'Location', 'northwest');

subplot(3,1,2);
plot(time_vec, P_gimp, 'LineWidth', 1.4); hold on;
plot(time_vec, -P_gexp, 'LineWidth', 1.4);
yline(0, 'k-'); grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('Grid Import and Export');
legend('P_{grid,imp}', '-P_{grid,exp}', 'Location', 'northwest');

subplot(3,1,3);
area(time_vec, P_curt, 'FaceAlpha', 0.5);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('PV Curtailment');
sgtitle('Phase 0: No-Storage PV/Grid Baseline');

%% 5) Daily energy and cost summary
[total_cost, cost_results] = calculate_costs(...
    P_gimp, P_gexp, params.dt);
E_pv_total = sum(P_pv) * params.dt;
E_load_total = sum(P_load) * params.dt;
E_curt_total = sum(P_curt) * params.dt;

fprintf('===== Phase 0 Daily Energy and Cost Summary =====\n');
fprintf('PV generated        : %6.2f kWh\n', E_pv_total);
fprintf('Load consumed       : %6.2f kWh\n', E_load_total);
fprintf('Grid imported       : %6.2f kWh\n', cost_results.E_gimp);
fprintf('Grid exported       : %6.2f kWh\n', cost_results.E_gexp);
fprintf('PV curtailed        : %6.2f kWh\n', E_curt_total);
fprintf('Energy cost         : %6.2f Rs\n', cost_results.energy_cost);
fprintf('Export compensation : %6.2f Rs\n', cost_results.export_compensation);
fprintf('Total cost          : %6.2f Rs\n', total_cost);
fprintf('=================================================\n');