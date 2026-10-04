function results = run_cloudy_cost_comparison()
%RUN_CLOUDY_COST_COMPARISON Compare cloudy-day costs across all EMS models.

    results = prepare_cloudy_comparison();
    plot_cloudy_cost_comparison(results.cloudy);
    assert(results.cloudy.phase2.total_cost < results.cloudy.phase1.total_cost, ...
        'run_cloudy_cost_comparison:lpNotLowerThanHeuristic', ...
        'Cloudy LP electricity bill must be lower than the heuristic bill.');
end
