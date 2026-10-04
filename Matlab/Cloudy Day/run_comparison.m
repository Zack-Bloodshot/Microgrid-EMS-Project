function results = run_comparison()
%RUN_COMPARISON Generate the no-battery household comparison figure.

    results = prepare_household_baseline();
    plot_baseline_comparison(results.sunny, results.cloudy);
end
