function outputs = generate_presentation_outputs()
%GENERATE_PRESENTATION_OUTPUTS Create concise figures and a CSV for slides.
%
%   outputs = GENERATE_PRESENTATION_OUTPUTS() runs the current sunny and
%   cloudy simulations using the shared pipeline and writes presentation-
%   ready files to General Notes/assets:
%
%     presentation-cost-comparison.png
%     presentation-dispatch-soc.png
%     presentation-alpha-sweep.png
%     presentation-summary.csv
%
%   The figures use the current system parameters and do not alter the EMS
%   model or its results.

    matlab_dir = fileparts(mfilename('fullpath'));
    addpath(matlab_dir, ...
        fullfile(matlab_dir, 'Stage0'), ...
        fullfile(matlab_dir, 'Stage1'), ...
        fullfile(matlab_dir, 'Stage2'), ...
        fullfile(matlab_dir, 'Stage3'), ...
        fullfile(matlab_dir, 'Comparison'));

    params = system_params();
    tariff = tariff_params();
    [sunny_pv, time] = generate_pv_profile(params);
    [load_profile, load_time] = generate_load_profile(params);
    [cloudy_pv, cloudy_time] = cloudy_profile_1(params);

    assert(isequal(time, load_time) && isequal(time, cloudy_time), ...
        'generate_presentation_outputs:timeMismatch', ...
        'PV, load, and cloudy profiles must share one time vector.');

    sunny = simulate_day(sunny_pv, load_profile, params, tariff, 1);
    cloudy = simulate_day(cloudy_pv, load_profile, params, tariff, 1);

    project_root = fileparts(matlab_dir);
    assets_dir = fullfile(project_root, 'General Notes', 'assets');
    if ~exist(assets_dir, 'dir')
        mkdir(assets_dir);
    end

    save_cost_figure(sunny, cloudy, assets_dir);
    save_dispatch_figure(sunny, cloudy, sunny_pv, cloudy_pv, ...
        load_profile, time, params, assets_dir);
    save_alpha_figure(assets_dir);
    summary = make_summary(sunny, cloudy);
    summary_path = fullfile(assets_dir, 'presentation-summary.csv');
    writetable(summary, summary_path);

    outputs = struct( ...
        'sunny', sunny, ...
        'cloudy', cloudy, ...
        'summary', summary, ...
        'assets_dir', assets_dir, ...
        'summary_path', summary_path);

    fprintf('\nPresentation outputs written to:\n%s\n', assets_dir);
    fprintf('  presentation-cost-comparison.png\n');
    fprintf('  presentation-dispatch-soc.png\n');
    fprintf('  presentation-alpha-sweep.png\n');
    fprintf('  presentation-summary.csv\n\n');
end

function save_cost_figure(sunny, cloudy, assets_dir)
    stages = {'Stage 0', 'Stage 1', 'Stage 2', 'Stage 3'};
    scenarios = {sunny, cloudy};
    daily = zeros(2, 4);
    grid_cost = zeros(2, 4);
    degradation = zeros(2, 4);

    for s = 1:2
        r = scenarios{s};
        daily(s, :) = [r.stage0.total_cost, r.stage1.total_cost, ...
            r.stage2.total_cost, r.stage3.total_cost];
        grid_cost(s, :) = [r.stage0.grid_cost, r.stage1.grid_cost, ...
            r.stage2.grid_cost, r.stage3.grid_cost];
        degradation(s, :) = [r.stage0.degradation_cost, ...
            r.stage1.degradation_cost, r.stage2.degradation_cost, ...
            r.stage3.degradation_cost];
    end

    fig = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100, 100, 1100, 700]);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    bar(daily.');
    grid on;
    set(gca, 'XTick', 1:4, 'XTickLabel', stages);
    ylabel('Total cost [Rs/day]');
    title('Total cost');
    legend('Sunny', 'Cloudy', 'Location', 'northwest');

    nexttile;
    bar([grid_cost(1, :).', degradation(1, :).'], 'stacked');
    grid on;
    set(gca, 'XTick', 1:4, 'XTickLabel', stages);
    ylabel('Cost [Rs/day]');
    title('Sunny-day cost components');
    legend('Grid', 'Battery wear', 'Location', 'northwest');

    nexttile;
    bar([grid_cost(2, :).', degradation(2, :).'], 'stacked');
    grid on;
    set(gca, 'XTick', 1:4, 'XTickLabel', stages);
    ylabel('Cost [Rs/day]');
    title('Cloudy-day cost components');
    legend('Grid', 'Battery wear', 'Location', 'northwest');

    nexttile;
    efc = [0, sunny.stage1.EFC, sunny.stage2.EFC, sunny.stage3.EFC; ...
        0, cloudy.stage1.EFC, cloudy.stage2.EFC, cloudy.stage3.EFC];
    bar(efc.');
    grid on;
    set(gca, 'XTick', 1:4, 'XTickLabel', stages);
    ylabel('Equivalent full cycles/day');
    title('Battery cycling');
    legend('Sunny', 'Cloudy', 'Location', 'northwest');

    sgtitle('EMS comparison under sunny and cloudy profiles');
    exportgraphics(fig, fullfile(assets_dir, ...
        'presentation-cost-comparison.png'), 'Resolution', 180);
    close(fig);
end

function save_dispatch_figure(sunny, cloudy, sunny_pv, cloudy_pv, ...
        load_profile, time, params, assets_dir)
    fig = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100, 100, 1100, 760]);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    cases = {sunny, cloudy};
    pv_profiles = {sunny_pv, cloudy_pv};
    names = {'Sunny', 'Cloudy'};

    for i = 1:2
        r = cases{i};
        p = r.stage3;
        nexttile;
        plot(time, pv_profiles{i}, 'LineWidth', 1.5); hold on;
        plot(time, load_profile, 'LineWidth', 1.5);
        plot(time, p.P_gimp, 'LineWidth', 1.3);
        plot(time, -p.P_gexp, 'LineWidth', 1.3);
        yline(0, 'k-');
        grid on; xlim([0 24]);
        xlabel('Time [h]'); ylabel('Power [kW]');
        title(sprintf('%s: Stage 3 power dispatch', names{i}));
        legend('PV', 'Load', 'Grid import', '-Grid export', ...
            'Location', 'northwest');

        nexttile;
        plot([time, 24], p.SOC, 'LineWidth', 1.8);
        hold on;
        yline(params.SOC_min, 'r--');
        yline(params.SOC_max, 'r--');
        yline(params.SOC0, 'k:');
        grid on; xlim([0 24]); ylim([0 1]);
        xlabel('Time [h]'); ylabel('SOC [-]');
        title(sprintf('%s: Stage 3 battery SOC', names{i}));
        legend('SOC', 'SOC limits', '', 'Initial SOC', ...
            'Location', 'best');
    end

    sgtitle('Stage 3 behavior in two weather conditions');
    exportgraphics(fig, fullfile(assets_dir, ...
        'presentation-dispatch-soc.png'), 'Resolution', 180);
    close(fig);
end

function save_alpha_figure(assets_dir)
    sweep = run_alpha_sweep([], false);
    fig = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100, 100, 950, 620]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot(sweep.alpha, sweep.total_cost, 'o-', 'LineWidth', 1.8);
    grid on;
    xlabel('\alpha [-]'); ylabel('Total physical cost [Rs/day]');
    title('Total cost versus degradation weight');

    nexttile;
    yyaxis left;
    plot(sweep.alpha, sweep.EFC, 'o-', 'LineWidth', 1.8);
    ylabel('EFC/day');
    yyaxis right;
    plot(sweep.alpha, sweep.grid_cost, 's--', 'LineWidth', 1.5);
    ylabel('Grid cost [Rs/day]');
    xlabel('\alpha [-]');
    grid on;
    title('Battery cycling and grid cost trade-off');
    legend('EFC', 'Grid cost', 'Location', 'best');

    sgtitle('Stage 3 sensitivity to battery-wear valuation');
    exportgraphics(fig, fullfile(assets_dir, ...
        'presentation-alpha-sweep.png'), 'Resolution', 180);
    close(fig);
end

function summary = make_summary(sunny, cloudy)
    scenario = {'Sunny'; 'Sunny'; 'Sunny'; 'Sunny'; ...
        'Cloudy'; 'Cloudy'; 'Cloudy'; 'Cloudy'};
    controller = {'Stage 0'; 'Stage 1'; 'Stage 2'; 'Stage 3'; ...
        'Stage 0'; 'Stage 1'; 'Stage 2'; 'Stage 3'};
    runs = {sunny.stage0; sunny.stage1; sunny.stage2; sunny.stage3; ...
        cloudy.stage0; cloudy.stage1; cloudy.stage2; cloudy.stage3};

    grid_cost = cellfun(@(r) r.grid_cost, runs);
    degradation_cost = cellfun(@(r) r.degradation_cost, runs);
    total_cost = cellfun(@(r) r.total_cost, runs);
    efc = zeros(8, 1);
    efc(2:4) = [sunny.stage1.EFC; sunny.stage2.EFC; sunny.stage3.EFC];
    efc(6:8) = [cloudy.stage1.EFC; cloudy.stage2.EFC; cloudy.stage3.EFC];

    summary = table(scenario, controller, grid_cost, degradation_cost, ...
        total_cost, efc, 'VariableNames', {'Scenario', 'Controller', ...
        'GridCost_RsPerDay', 'DegradationCost_RsPerDay', ...
        'TotalCost_RsPerDay', 'EFCPerDay'});
end
