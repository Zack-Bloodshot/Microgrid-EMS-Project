function plot_cloudy_cost_comparison(cloudy)
%PLOT_CLOUDY_COST_COMPARISON Plot cloudy baseline, heuristic, and LP costs.

    phase_names = {'Baseline', 'Heuristic EMS', 'LP EMS'};
    daily_total = [cloudy.phase0.total_cost, ...
        cloudy.phase1.total_cost, cloudy.phase2.total_cost];
    daily_grid = [cloudy.phase0.grid_cost, ...
        cloudy.phase1.grid_cost, cloudy.phase2.grid_cost];
    daily_degradation = [cloudy.phase0.degradation_cost, ...
        cloudy.phase1.degradation_cost, cloudy.phase2.degradation_cost];
    monthly_total = 30 * daily_total;

    figure('Name', 'Cloudy-Day EMS Cost Comparison', ...
        'Position', [150, 100, 1150, 700]);
    subplot(1, 3, 1);
    bar(daily_total);
    set(gca, 'XTick', 1:3, 'XTickLabel', phase_names);
    ylabel('Cost [Rs/day]');     title('Daily electricity bill'); grid on;

    subplot(1, 3, 2);
    bar(monthly_total);
    set(gca, 'XTick', 1:3, 'XTickLabel', phase_names);
    ylabel('Cost [Rs/month]'); title('30-day electricity bill'); grid on;

    subplot(1, 3, 3);
    bar([daily_grid; daily_degradation].');
    set(gca, 'XTick', 1:3, 'XTickLabel', phase_names);
    ylabel('Cost [Rs/day]'); title('Daily cost components'); grid on;
    legend('Grid cost (includes fixed charge)', ...
        'Post-hoc battery degradation', 'Location', 'northwest');
    sgtitle('Cloudy-day electricity bill: baseline vs heuristic vs LP');
end
