function results = run_lp_comparison()
%RUN_LP_COMPARISON Generate sunny-versus-cloudy LP EMS plots.

    results = prepare_cloudy_comparison();
    plot_ems_comparison(results.sunny, results.cloudy, 'phase2', 'LP EMS');
end
