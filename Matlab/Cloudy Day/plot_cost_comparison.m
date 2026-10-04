function plot_cost_comparison(sunny, cloudy)
%PLOT_COST_COMPARISON Plot daily and monthly costs for sunny and cloudy days.

    scenario_names = {'Sunny', 'Cloudy'};
    phase_names = {'Baseline', 'Heuristic EMS', 'LP EMS'};
    scenarios = {sunny, cloudy};
    daily_costs = zeros(2, 3);
    grid_costs = zeros(2, 3);

    for scenario_index = 1:numel(scenarios)
        scenario = scenarios{scenario_index};
        daily_costs(scenario_index, :) = [ ...
            scenario.phase0.total_cost, ...
            scenario.phase1.total_cost, ...
            scenario.phase2.total_cost];
        grid_costs(scenario_index, :) = [ ...
            scenario.phase0.grid_cost, ...
            scenario.phase1.grid_cost, ...
            scenario.phase2.grid_cost];
    end

    figure('Name', 'Sunny and Cloudy Cost Comparison', ...
        'Position', [150, 100, 1100, 700]);
    subplot(1, 3, 1);
    grouped_bars(daily_costs, scenario_names, phase_names, ...
        'Daily total cost', 'Cost [Rs/day]');
    subplot(1, 3, 2);
    grouped_bars(30 * daily_costs, scenario_names, phase_names, ...
        'Monthly total cost', 'Cost [Rs/month]');
    subplot(1, 3, 3);
    grouped_bars(grid_costs, scenario_names, phase_names, ...
        'Daily grid cost', 'Cost [Rs/day]');
    sgtitle('Cost comparison: sunny vs. cloudy');
end

function grouped_bars(costs, scenario_names, phase_names, plot_title, y_label)
    bar(costs);
    grid on;
    set(gca, 'XTick', 1:numel(scenario_names), ...
        'XTickLabel', scenario_names);
    ylabel(y_label);
    title(plot_title);
    legend(phase_names, 'Location', 'northwest');
end
