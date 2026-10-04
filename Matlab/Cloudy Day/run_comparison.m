function results = run_comparison()
%RUN_COMPARISON Generate the sunny-versus-cloudy cost comparison figure.
%
%   results.energy.sunny.baseline / .heuristic / .lp and
%   results.energy.cloudy.baseline / .heuristic / .lp each contain
%   kwh_consumed, kwh_import, and kwh_export for the day.

    results = prepare_cloudy_comparison();
    plot_cost_comparison(results.sunny, results.cloudy);
    plot_daily_details(results.sunny, results.cloudy);
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
