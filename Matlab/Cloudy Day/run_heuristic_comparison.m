function results = run_heuristic_comparison()
%RUN_HEURISTIC_COMPARISON Generate sunny-versus-cloudy heuristic plots.

    results = prepare_cloudy_comparison();
    plot_ems_comparison(results.sunny, results.cloudy, 'phase1', ...
        'Heuristic EMS');
end
