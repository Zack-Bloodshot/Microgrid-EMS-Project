function plot_comparison(sunny, cloudy)
%PLOT_COMPARISON Generate all sunny-vs-cloudy comparison plots.
%
%   plot_comparison(sunny, cloudy) creates:
%     1. Cost comparison figure (daily, monthly, grid costs)
%     2. Daily dispatch detail figures (PV, load, grid, battery for all phases)
%
%   This is the single entry point for all comparison plotting.
%   For per-phase EMS comparison plots, see plot_ems_comparison.m.

    plot_cost_bars(sunny, cloudy);
    plot_daily_details(sunny, cloudy);
end

function plot_cost_bars(sunny, cloudy)
%PLOT_COST_BARS Daily and monthly cost comparison bar charts.

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

function plot_daily_details(sunny, cloudy)
%PLOT_DAILY_DETAILS Detailed 24h dispatch plots for all six cases.
%
%   Creates two figure windows (one per scenario) each with three
%   subplots (baseline, heuristic, LP) showing PV vs load, grid
%   import/export, and battery charge/discharge.

    scenarios = {sunny, cloudy};
    scenario_names = {'Sunny', 'Cloudy'};
    phase_names = {'Baseline', 'Heuristic', 'LP'};
    phase_fields = {'phase0', 'phase1', 'phase2'};

    for s = 1:2
        scenario = scenarios{s};

        figure('Name', sprintf('Daily Dispatch Cost - %s', scenario_names{s}), ...
            'Position', [50 + (s - 1) * 750, 50, 700, 1000]);

        for p = 1:3
            phase = scenario.(phase_fields{p});
            subplot(3, 1, p);

            hold on;
            plot(scenario.time, scenario.P_pv, 'LineWidth', 1.2, ...
                'Color', [0.85, 0.65, 0.13]);
            plot(scenario.time, scenario.P_load, 'LineWidth', 1.2, ...
                'Color', [0.85, 0.33, 0.10]);
            plot(scenario.time, phase.P_gimp, 'LineWidth', 1.2, ...
                'Color', [0.00, 0.45, 0.74]);
            plot(scenario.time, -phase.P_gexp, 'LineWidth', 1.2, ...
                'Color', [0.00, 0.65, 0.30]);

            if p > 1
                plot(scenario.time, phase.P_ch, 'LineWidth', 1.0, ...
                    'Color', [0.49, 0.18, 0.56]);
                plot(scenario.time, -phase.P_dis, 'LineWidth', 1.0, ...
                    'Color', [0, 0, 0]);
            end

            yline(0, 'k-');
            grid on;
            xlim([0 24]);
            xlabel('Time [h]');
            ylabel('Power [kW]');
            title(sprintf('%s - %s (Rs%.2f/day)', ...
                scenario_names{s}, phase_names{p}, phase.total_cost));

            if p == 1
                legend('P_{pv}', 'P_{load}', 'P_{g,imp}', '-P_{g,exp}', ...
                    'Location', 'northwest', 'FontSize', 7);
            else
                legend('P_{pv}', 'P_{load}', 'P_{g,imp}', '-P_{g,exp}', ...
                    'P_{ch}', '-P_{dis}', 'Location', 'northwest', 'FontSize', 7);
            end
            hold off;
        end

        sgtitle(sprintf('Daily Dispatch Cost - %s', scenario_names{s}));
    end
end
