function results = run_comparison()
%RUN_COMPARISON Generate the sunny-versus-cloudy cost comparison figure.

    results = prepare_cloudy_comparison();
    plot_cost_comparison(results.sunny, results.cloudy);
end
