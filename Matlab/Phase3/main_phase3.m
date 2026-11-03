%% MAIN_PHASE3 - Phase 3 Degradation-Aware LP EMS: 24h Simulation Driver
%
%   Runs the complete Phase 3 pipeline:
%     1) Load system parameters              (system_params)
%     2) Generate deterministic PV profile    (generate_pv_profile)
%     3) Generate deterministic load profile  (generate_load_profile)
%     4) Load tariff data                     (tariff_params)
%     5) Solve the degradation-aware LP       (lp_degradation_aware_ems)
%     6) Validate the result                  (validate_phase3_solution)
%     7) Quantify DoD-aware degradation       (battery_degradation_dod)
%     8) Plot PV/load, dispatch, SOC, curtailment, and DoD
%
%   The headline case uses alpha = 1, i.e. battery wear is priced at its
%   modelled cost. Phase 2 remains frozen on its legacy degradation model.

clear; clc; close all;

%% Path setup
phase_dir = fileparts(mfilename('fullpath'));
matlab_dir = fileparts(phase_dir);
addpath(matlab_dir, ...
    fullfile(matlab_dir, 'Phase2'), ...
    fullfile(matlab_dir, 'Phase3'));

%% 1) Configuration
alpha = 1;   % degradation weight; 1 = price wear at modelled cost

params = system_params();
[P_pv, time_vec]    = generate_pv_profile(params);
[P_load, time_vec2] = generate_load_profile(params); %#ok<ASGLU>
tariff = tariff_params();

assert(isequal(size(P_pv), size(P_load)), ...
    'main_phase3:dimMismatch', 'P_pv and P_load must have identical dimensions.');
assert(numel(P_pv) == params.N, ...
    'main_phase3:dimMismatch', 'Profile length must equal params.N.');

%% 2) Solve the degradation-aware LP
[P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, grid_cost, deg_cost, ...
    objective_value] = ...
    lp_degradation_aware_ems(P_pv, P_load, tariff, params, alpha);

%% 3) Validate
report = validate_phase3_solution( ...
    P_pv, P_load, P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, params);

if ~report.all_checks_passed
    warning('main_phase3:validationFailed', ...
        'One or more Phase 3 validation checks failed. See summary above.');
end

%% 4) Degradation diagnostics
[deg_cost_check, EFC, DoD, LifeCycles] = ...
    battery_degradation_dod(P_ch, P_dis, params);
assert(abs(deg_cost_check - deg_cost) < 1e-9, ...
    'main_phase3:degCostMismatch', ...
    'deg_cost from lp_degradation_aware_ems and battery_degradation_dod disagree.');

%% 5) Plots
time_soc = (0:params.N) * params.dt;

figure('Name', 'Phase 3 Degradation-Aware LP EMS - 24h Simulation', ...
       'Position', [100, 80, 1050, 980]);

% --- Subplot 1: PV generation vs. Load demand ---
subplot(5,1,1);
plot(time_vec, P_pv, 'LineWidth', 1.6); hold on;
plot(time_vec, P_load, 'LineWidth', 1.6);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('PV Generation vs. Load Demand');
legend('P_{pv}', 'P_{load}', 'Location', 'northwest');

% --- Subplot 2: Dispatch ---
subplot(5,1,2);
plot(time_vec, P_ch,    'LineWidth', 1.4); hold on;
plot(time_vec, -P_dis,  'LineWidth', 1.4);
plot(time_vec, P_gimp,  'LineWidth', 1.4);
plot(time_vec, -P_gexp, 'LineWidth', 1.4);
yline(0, 'k-');
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('Degradation-Aware Dispatch (charge/import positive, discharge/export negative)');
legend('P_{ch}', '-P_{dis}', 'P_{grid,imp}', '-P_{grid,exp}', ...
    'Location', 'northwest');

% --- Subplot 3: Battery SOC ---
subplot(5,1,3);
plot(time_soc, SOC, 'LineWidth', 1.8); hold on;
yline(params.SOC_min, 'r--');
yline(params.SOC_max, 'r--');
yline(params.SOC0, 'k:', 'Terminal SOC target');
grid on; xlim([0 24]); ylim([0 1]);
xlabel('Time [h]'); ylabel('SOC [-]');
title(sprintf('Battery State of Charge (final = %.3f)', SOC(end)));
legend('SOC(k)', 'SOC_{min}/SOC_{max}', 'SOC_0', 'Location', 'northwest');

% --- Subplot 4: PV curtailment ---
subplot(5,1,4);
area(time_vec, P_curt, 'FaceAlpha', 0.5);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('Power [kW]');
title('PV Curtailment');

% --- Subplot 5: Per-timestep DoD stress ---
subplot(5,1,5);
bar(time_vec, DoD, 'BarWidth', 1);
grid on; xlim([0 24]);
xlabel('Time [h]'); ylabel('DoD(k) [-]');
title('Per-Timestep Throughput Slice (diagnostic only; not used for costing)');

sgtitle(sprintf( ...
    'Phase 3: Degradation-Aware LP EMS - \\alpha = %.2f (%s)', ...
    alpha, report.degradation_model));

% Save the figure for the Obsidian note (General Notes/assets).
project_root = fileparts(matlab_dir);
assets_dir = fullfile(project_root, 'General Notes', 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end
dispatch_path = fullfile(assets_dir, 'phase3-dispatch-soc.png');
exportgraphics(gcf, dispatch_path, 'Resolution', 150);
fprintf('\n Saved Phase 3 dispatch figure: %s\n', dispatch_path);

%% 6) Formatted console summary
E_pv_total   = sum(P_pv)   * params.dt;
E_load_total = sum(P_load) * params.dt;
E_ch_total   = sum(P_ch)   * params.dt;
E_dis_total  = sum(P_dis)  * params.dt;
E_gimp_total = sum(P_gimp) * params.dt;
E_gexp_total = sum(P_gexp) * params.dt;
E_curt_total = sum(P_curt) * params.dt;

fprintf('\n');
fprintf('==================================================================\n');
fprintf(' Phase 3 Daily Summary - Degradation-Aware LP EMS\n');
fprintf('==================================================================\n');
fprintf(' Alpha (degradation weight) : %.2f\n', alpha);
fprintf(' Degradation model          : %s\n', report.degradation_model);
fprintf(' Cost of wear               : %.4f Rs/kWh throughput\n', ...
    params.Cost_replacement / ...
    (params.N_cycles_rated * 2 * params.E_B * params.DoD_rated));
fprintf('------------------------------------------------------------------\n');
fprintf(' Energy\n');
fprintf('   PV generated       : %7.3f kWh\n', E_pv_total);
fprintf('   Load consumed      : %7.3f kWh\n', E_load_total);
fprintf('   Battery charged    : %7.3f kWh\n', E_ch_total);
fprintf('   Battery discharged : %7.3f kWh\n', E_dis_total);
fprintf('   Grid imported      : %7.3f kWh\n', E_gimp_total);
fprintf('   Grid exported      : %7.3f kWh\n', E_gexp_total);
fprintf('   PV curtailed       : %7.3f kWh\n', E_curt_total);
fprintf('------------------------------------------------------------------\n');
fprintf(' Cost\n');
fprintf('   Grid cost          : %7.2f Rs/day\n', grid_cost);
fprintf('   Degradation cost   : %7.2f Rs/day\n', deg_cost);
fprintf('   Total physical cost: %7.2f Rs/day\n', grid_cost + deg_cost);
fprintf('   Solver objective   : %7.2f Rs (alpha-weighted)\n', objective_value);
fprintf('------------------------------------------------------------------\n');
fprintf(' Battery\n');
fprintf('   Equivalent full cycles (EFC) : %7.3f\n', EFC);
fprintf('   Final SOC                    : %7.3f\n', SOC(end));
fprintf('   Validation                   : %s\n', ...
    ternary(report.all_checks_passed, 'PASS', 'FAIL'));
fprintf('==================================================================\n\n');

function out = ternary(condition, yes_text, no_text)
    if condition
        out = yes_text;
    else
        out = no_text;
    end
end
