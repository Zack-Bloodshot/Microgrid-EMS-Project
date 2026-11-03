function results = run_all_phases(alpha)
%RUN_ALL_PHASES Run and compare the Phase 0/1/2/3 EMS runs.
%   results = RUN_ALL_PHASES() uses alpha = 1 for Phase 3.
%   results = RUN_ALL_PHASES(alpha) sets the Phase 3 degradation weight.

    if nargin < 1 || isempty(alpha)
        alpha = 1;
    end

    matlab_dir = fileparts(mfilename('fullpath'));
    addpath(matlab_dir, ...
        fullfile(matlab_dir, 'Phase0'), ...
        fullfile(matlab_dir, 'Phase1'), ...
        fullfile(matlab_dir, 'Phase2'), ...
        fullfile(matlab_dir, 'Phase3'));

    %% Shared inputs
    params = system_params();
    [P_pv, time_vec] = generate_pv_profile(params);
    [P_load, time_vec_load] = generate_load_profile(params);
    assert(isequal(time_vec, time_vec_load), ...
        'run_all_phases:timeMismatch', 'PV and load time vectors must match.');

    %% Run all 4 phases via the shared simulation pipeline
    results = simulate_day(P_pv, P_load, params, tariff_params(), alpha);

    results.params = params;
    results.P_pv = P_pv;
    results.P_load = P_load;
    results.time = time_vec;

    %% Console comparison
    phase_names = {'Phase 0', 'Phase 1', 'Phase 2', 'Phase 3'};
    grid_costs = [results.phase0.grid_cost, results.phase1.grid_cost, ...
        results.phase2.grid_cost, results.phase3.grid_cost];
    degradation_costs = [results.phase0.degradation_cost, ...
        results.phase1.degradation_cost, results.phase2.degradation_cost, ...
        results.phase3.degradation_cost];
    total_costs = grid_costs + degradation_costs;
    monthly_total_costs = 30 * total_costs;
    efc = [0, results.phase1.EFC, results.phase2.EFC, results.phase3.EFC];
    models = {'none', 'legacy 100% DoD', 'legacy 100% DoD', ...
        results.phase3.validation.degradation_model};

    fprintf('\n');
    fprintf('==========================================================================================\n');
    fprintf(' All-Phase Cost Comparison  (Phase 3 alpha = %.2f)\n', alpha);
    fprintf('==========================================================================================\n');
    fprintf(' %-8s %11s %11s %11s %12s %8s  %s\n', ...
        'Phase', 'Grid/day', 'Degr./day', 'Total/day', 'Total/month', ...
        'EFC', 'Degradation model');
    fprintf(' %-8s %11s %11s %11s %12s %8s  %s\n', ...
        '', '[Rs]', '[Rs]', '[Rs]', '[Rs]', '[-]', '');
    fprintf('------------------------------------------------------------------------------------------\n');
    for i = 1:numel(phase_names)
        fprintf(' %-8s %11.2f %11.2f %11.2f %12.1f %8.3f  %s\n', ...
            phase_names{i}, grid_costs(i), degradation_costs(i), ...
            total_costs(i), monthly_total_costs(i), efc(i), models{i});
    end
    fprintf('------------------------------------------------------------------------------------------\n');

    % Like-for-like view: Phase 2's dispatch repriced under the Phase 3 model.
    [phase2_deg_p3, phase2_efc_p3] = ...
        battery_degradation_dod(results.phase2.P_ch, results.phase2.P_dis, params);
    fprintf(' Reference: Phase 2 dispatch repriced under the Phase 3 wear model\n');
    fprintf('            grid Rs %.2f + wear Rs %.2f = Rs %.2f/day (EFC %.3f)\n', ...
        results.phase2.grid_cost, phase2_deg_p3, ...
        results.phase2.grid_cost + phase2_deg_p3, phase2_efc_p3);
    fprintf('            Phase 2 as reported above still uses the frozen legacy model.\n');
    fprintf('==========================================================================================\n\n');

    %% Cost comparison plot
    figure('Name', 'All-Phase EMS Cost Comparison', ...
        'Position', [150, 120, 950, 620]);
    subplot(2, 1, 1);
    bar([grid_costs; degradation_costs].', 'stacked');
    grid on;
    set(gca, 'XTick', 1:numel(phase_names), 'XTickLabel', phase_names);
    ylabel('Cost [Rs/day]');
    title('Daily Cost Components (grid + degradation)');
    legend('Grid cost', 'Degradation cost', 'Location', 'northwest');

    subplot(2, 1, 2);
    bar(monthly_total_costs);
    grid on;
    set(gca, 'XTick', 1:numel(phase_names), 'XTickLabel', phase_names);
    ylabel('Cost [Rs/month]');
    title('30-Day Equivalent Household Bill');
    sgtitle('Phase 0 vs. Phase 1 vs. Phase 2 vs. Phase 3');

    % Save the figure for the Obsidian note (General Notes/assets).
    project_root = fileparts(matlab_dir);
    assets_dir = fullfile(project_root, 'General Notes', 'assets');
    if ~exist(assets_dir, 'dir')
        mkdir(assets_dir);
    end
    comparison_path = fullfile(assets_dir, 'all-phase-cost-comparison.png');
    exportgraphics(gcf, comparison_path, 'Resolution', 150);
    fprintf(' Saved all-phase cost figure: %s\n', comparison_path);
end
