    function results = run_all_phases()
%RUN_ALL_PHASES Run and compare the Phase 0, Phase 1, and Phase 2 EMS runs.
    matlab_dir = fileparts(mfilename('fullpath'));
    addpath(matlab_dir, ...
        fullfile(matlab_dir, 'Phase0'), ...
        fullfile(matlab_dir, 'Phase1'), ...
        fullfile(matlab_dir, 'Phase2'));

    %% Shared inputs
    params = system_params();
    [P_pv, time_vec] = generate_pv_profile(params);
    [P_load, time_vec_load] = generate_load_profile(params);
    assert(isequal(time_vec, time_vec_load), ...
        'run_all_phases:timeMismatch', 'PV and load time vectors must match.');

    %% Run all 3 phases via shared simulation pipeline
    results = simulate_day(P_pv, P_load, params);

    results.params = params;
    results.P_pv = P_pv;
    results.P_load = P_load;
    results.time = time_vec;

    %% Console comparison
    phase_names = {'Phase 0', 'Phase 1', 'Phase 2'};
    grid_costs = [results.phase0.grid_cost, results.phase1.grid_cost, ...
        results.phase2.grid_cost];
    degradation_costs = [results.phase0.degradation_cost, ...
        results.phase1.degradation_cost, results.phase2.degradation_cost];
    total_costs = grid_costs + degradation_costs;
    monthly_total_costs = 30 * total_costs;

    fprintf('\n===== All-Phase Cost Comparison =====\n');
    fprintf('%-12s %15s %18s %15s %18s\n', ...
        'Phase', 'Grid/day (Rs)', 'Degradation/day (Rs)', ...
        'Total/day (Rs)', 'Total/month (Rs)');
    for phase_index = 1:numel(phase_names)
        fprintf('%-12s %15.2f %18.2f %15.2f %18.2f\n', phase_names{phase_index}, ...
            grid_costs(phase_index), degradation_costs(phase_index), ...
            total_costs(phase_index), monthly_total_costs(phase_index));
    end
    fprintf('=====================================\n');

    %% Cost comparison plot
    figure('Name', 'All-Phase EMS Cost Comparison', ...
        'Position', [150, 150, 900, 600]);
    subplot(2, 1, 1);
    bar([grid_costs; degradation_costs].', 'stacked');
    grid on;
    set(gca, 'XTick', 1:numel(phase_names), 'XTickLabel', phase_names);
    ylabel('Cost [Rs]');
    title('Daily Cost Components');
    legend('Grid cost', 'Post-hoc degradation cost', 'Location', 'northwest');

    subplot(2, 1, 2);
    bar(monthly_total_costs);
    grid on;
    set(gca, 'XTick', 1:numel(phase_names), 'XTickLabel', phase_names);
    ylabel('Cost [Rs]');
    title('30-Day Equivalent Household Bill');
    sgtitle('Phase 0 vs. Phase 1 vs. Phase 2');
end