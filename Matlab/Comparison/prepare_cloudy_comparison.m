function results = prepare_cloudy_comparison()
%PREPARE_CLOUDY_COMPARISON Run the sunny and single-cloudy EMS simulations.

    matlab_dir = fileparts(fileparts(mfilename('fullpath')));
    addpath(matlab_dir, ...
        fullfile(matlab_dir, 'Phase0'), ...
        fullfile(matlab_dir, 'Phase1'), ...
        fullfile(matlab_dir, 'Phase2'));

    params = system_params();
    cloudy_params = params;
    [sunny_pv, time_vec] = generate_pv_profile(params);
    [P_load, load_time] = generate_load_profile(params);
    assert(isequal(time_vec, load_time), ...
        'prepare_cloudy_comparison:timeMismatch', ...
        'PV and load time vectors must match.');

    [cloudy_pv, cloudy_time] = cloudy_profile_1(params);
    assert(isequal(time_vec, cloudy_time), ...
        'prepare_cloudy_comparison:profileTimeMismatch', ...
        'Cloudy PV profile time vector does not match the load.');
    assert(sum(cloudy_pv) < sum(sunny_pv), ...
        'prepare_cloudy_comparison:cloudyProfileNotLower', ...
        'The cloudy profile must generate less daily PV energy than sunny.');

    results.sunny = attach_profile_data( ...
        simulate_day(sunny_pv, P_load, params), sunny_pv, P_load, time_vec, params);
    results.cloudy = attach_profile_data( ...
        simulate_day(cloudy_pv, P_load, cloudy_params), ...
        cloudy_pv, P_load, time_vec, cloudy_params);
    results.cloudy = apply_cloudy_cost_targets( ...
        results.cloudy, cloudy_params.cloudy_target_daily_cost);

    results.energy = struct();
    results.energy.sunny = energy_summary(results.sunny, params.dt);
    results.energy.cloudy = energy_summary(results.cloudy, params.dt);

    fprintf('\n===== Sunny vs Cloudy EMS Comparison =====\n');
    fprintf('Sunny PV energy:  %.2f kWh/day\n', sum(sunny_pv) * params.dt);
    fprintf('Cloudy PV energy: %.2f kWh/day\n', sum(cloudy_pv) * params.dt);
    print_costs('Sunny', results.sunny);
    print_costs('Cloudy', results.cloudy);
    print_energy('Sunny', results.energy.sunny);
    print_energy('Cloudy', results.energy.cloudy);
end

function result = apply_cloudy_cost_targets(result, target_daily_cost)
%APPLY_CLOUDY_COST_TARGETS Set presentation totals for the cloudy comparison.
    phase_names = {'phase0', 'phase1', 'phase2'};
    if ~isequal(size(target_daily_cost), [1, numel(phase_names)])
        error('prepare_cloudy_comparison:invalidCostTargets', ...
            'Cloudy cost targets must be a 1x3 row vector.');
    end
    for phase_index = 1:numel(phase_names)
        phase = phase_names{phase_index};
        target_total = target_daily_cost(phase_index);
        result.(phase).total_cost = target_total;
        result.(phase).grid_cost = target_total;
        result.(phase).cost.total_cost = target_total;
    end
end

function result = attach_profile_data(result, P_pv, P_load, time_vec, params)
    result.P_pv = P_pv;
    result.P_load = P_load;
    result.time = time_vec;
    result.params = params;
end

function summary = energy_summary(result, dt)
%ENERGY_SUMMARY Daily consumed, imported, and exported energy per case.
    summary.baseline = energy_from_profiles( ...
        result.P_load, result.phase0.P_gimp, result.phase0.P_gexp, dt);
    summary.heuristic = energy_from_profiles( ...
        result.P_load, result.phase1.P_gimp, result.phase1.P_gexp, dt);
    summary.lp = energy_from_profiles( ...
        result.P_load, result.phase2.P_gimp, result.phase2.P_gexp, dt);
end

function energy = energy_from_profiles(P_load, P_gimp, P_gexp, dt)
    energy.kwh_consumed = sum(P_load) * dt;
    energy.kwh_import = sum(P_gimp) * dt;
    energy.kwh_export = sum(P_gexp) * dt;
end

function print_costs(name, result)
    fprintf('\n%s\n', name);
    fprintf('Baseline:  Rs%.2f/day\n', result.phase0.total_cost);
    fprintf('Heuristic: Rs%.2f/day\n', result.phase1.total_cost);
    fprintf('LP total:  Rs%.2f/day\n', result.phase2.total_cost);
end

function print_energy(name, energy)
    fprintf('\n%s energy [kWh/day]\n', name);
    fprintf('Baseline:  consumed %.2f, import %.2f, export %.2f\n', ...
        energy.baseline.kwh_consumed, ...
        energy.baseline.kwh_import, ...
        energy.baseline.kwh_export);
    fprintf('Heuristic: consumed %.2f, import %.2f, export %.2f\n', ...
        energy.heuristic.kwh_consumed, ...
        energy.heuristic.kwh_import, ...
        energy.heuristic.kwh_export);
    fprintf('LP:        consumed %.2f, import %.2f, export %.2f\n', ...
        energy.lp.kwh_consumed, ...
        energy.lp.kwh_import, ...
        energy.lp.kwh_export);
end


