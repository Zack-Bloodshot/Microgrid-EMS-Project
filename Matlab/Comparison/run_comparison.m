function results = run_comparison()
%RUN_COMPARISON Generate the sunny-versus-cloudy cost comparison figure.
%
%   results.energy.sunny.baseline / .heuristic / .lp and
%   results.energy.cloudy.baseline / .heuristic / .lp each contain
%   kwh_consumed, kwh_import, and kwh_export for the day.

    results = prepare_cloudy_comparison();
    plot_comparison(results.sunny, results.cloudy);
end
