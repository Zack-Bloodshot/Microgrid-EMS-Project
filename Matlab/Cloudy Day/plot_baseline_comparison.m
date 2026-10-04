function plot_baseline_comparison(sunny, cloudy)
%PLOT_BASELINE_COMPARISON Plot no-controller sunny/cloudy household costs.

    daily_costs = [sunny.daily_cost, cloudy.daily_cost];
    monthly_costs = [sunny.monthly_cost, cloudy.monthly_cost];
    import_energy = [sunny.cost.E_gimp, cloudy.cost.E_gimp];
    export_energy = [sunny.cost.E_gexp, cloudy.cost.E_gexp];
    labels = {'Sunny', 'Cloudy'};

    figure('Name', 'Household Sunny and Cloudy Baseline', ...
        'Position', [150, 100, 1100, 700]);
    subplot(1, 3, 1);
    bar(daily_costs);
    set(gca, 'XTick', 1:2, 'XTickLabel', labels);
    ylabel('Cost [Rs/day]'); title('Daily bill'); grid on;

    subplot(1, 3, 2);
    bar(monthly_costs);
    set(gca, 'XTick', 1:2, 'XTickLabel', labels);
    ylabel('Cost [Rs/month]'); title('30-day bill'); grid on;

    subplot(1, 3, 3);
    bar([import_energy; export_energy].');
    set(gca, 'XTick', 1:2, 'XTickLabel', labels);
    ylabel('Energy [kWh/day]'); title('Grid exchange'); grid on;
    legend('Grid import', 'Solar export', 'Location', 'northwest');
    sgtitle('Actual household baseline: no battery and no controller');
end
