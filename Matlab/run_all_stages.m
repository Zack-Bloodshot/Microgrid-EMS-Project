-function results = run_all_stages(alpha)
%RUN_ALL_STAGES Run and compare the Stage 0/1/2/3 EMS runs.
%   results = RUN_ALL_STAGES() uses alpha = 1 for Stage 3.
%   results = RUN_ALL_STAGES(alpha) sets the Stage 3 degradation weight.

    if nargin < 1 || isempty(alpha)
        alpha = 1;
    end

    matlab_dir = fileparts(mfilename('fullpath'));
    addpath(matlab_dir, ...
        fullfile(matlab_dir, 'Stage0'), ...
        fullfile(matlab_dir, 'Stage1'), ...
        fullfile(matlab_dir, 'Stage2'), ...
        fullfile(matlab_dir, 'Stage3'));

    %% Shared inputs
    params = system_params();
    [P_pv, time_vec] = generate_pv_profile(params);
    [P_load, time_vec_load] = generate_load_profile(params);
    assert(isequal(time_vec, time_vec_load), ...
        'run_all_stages:timeMismatch', 'PV and load time vectors must match.');

    %% Run all 4 stages via the shared simulation pipeline
    results = simulate_day(P_pv, P_load, params, tariff_params(), alpha);

    results.params = params;
    results.P_pv = P_pv;
    results.P_load = P_load;
    results.time = time_vec;

    %% Console comparison
    stage_names = {'Stage 0', 'Stage 1', 'Stage 2', 'Stage 3'};
    grid_costs = [results.stage0.grid_cost, results.stage1.grid_cost, ...
        results.stage2.grid_cost, results.stage3.grid_cost];
    degradation_costs = [results.stage0.degradation_cost, ...
        results.stage1.degradation_cost, results.stage2.degradation_cost, ...
        results.stage3.degradation_cost];
    total_costs = grid_costs + degradation_costs;
    monthly_total_costs = 30 * total_costs;
    efc = [0, results.stage1.EFC, results.stage2.EFC, results.stage3.EFC];
    models = {'none', results.stage1.degradation_model, ...
        results.stage2.degradation_model, results.stage3.degradation_model};

    fprintf('\n');
    fprintf('==========================================================================================\n');
    fprintf(' All-Stage Cost Comparison  (Stage 3 alpha = %.2f)\n', alpha);
    fprintf('==========================================================================================\n');
    fprintf(' %-8s %11s %11s %11s %12s %8s  %s\n', ...
        'Stage', 'Grid/day', 'Degr./day', 'Total/day', 'Total/month', ...
        'EFC', 'Degradation model');
    fprintf(' %-8s %11s %11s %11s %12s %8s  %s\n', ...
        '', '[Rs]', '[Rs]', '[Rs]', '[Rs]', '[-]', '');
    fprintf('------------------------------------------------------------------------------------------\n');
    for i = 1:numel(stage_names)
        fprintf(' %-8s %11.2f %11.2f %11.2f %12.1f %8.3f  %s\n', ...
            stage_names{i}, grid_costs(i), degradation_costs(i), ...
            total_costs(i), monthly_total_costs(i), efc(i), models{i});
    end
    fprintf('------------------------------------------------------------------------------------------\n');
    fprintf(' All stages use the same wear model, so degradation columns are comparable.\n');
    fprintf('==========================================================================================\n\n');

    %% Cost comparison plot
    figure('Name', 'All-Stage EMS Cost Comparison', ...
        'Position', [150, 120, 950, 620]);
    subplot(2, 1, 1);
    bar([grid_costs; degradation_costs].', 'stacked');
    grid on;
    set(gca, 'XTick', 1:numel(stage_names), 'XTickLabel', stage_names);
    ylabel('Cost [Rs/day]');
    title('Daily Cost Components (grid + degradation)');
    legend('Grid cost', 'Degradation cost', 'Location', 'northwest');

    subplot(2, 1, 2);
    bar(monthly_total_costs);
    grid on;
    set(gca, 'XTick', 1:numel(stage_names), 'XTickLabel', stage_names);
    ylabel('Cost [Rs/month]');
    title('30-Day Equivalent Household Bill');
    sgtitle('Stage 0 vs. Stage 1 vs. Stage 2 vs. Stage 3');

    % Save the figure for the Obsidian note (General Notes/assets).
    project_root = fileparts(matlab_dir);
    assets_dir = fullfile(project_root, 'General Notes', 'assets');
    if ~exist(assets_dir, 'dir')
        mkdir(assets_dir);
    end
    comparison_path = fullfile(assets_dir, 'all-stage-cost-comparison.png');
    exportgraphics(gcf, comparison_path, 'Resolution', 150);
    fprintf(' Saved all-stage cost figure: %s\n', comparison_path);
end
