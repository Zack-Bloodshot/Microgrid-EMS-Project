function results = prepare_household_baseline()
%PREPARE_HOUSEHOLD_BASELINE Simulate the real household without EMS storage.
%
%   This represents the APDCL bill scenario: PV serves the household
%   directly, grid import covers deficits, and surplus PV is exported.
%   No battery, battery controller, or optimization is used.

    matlab_dir = fileparts(fileparts(mfilename('fullpath')));
    addpath(matlab_dir, fullfile(matlab_dir, 'Phase 0'));

    params = system_params();
    params.household_monthly_kWh = 303.55;
    params.billing_days = 30;
    params.connected_load_kW = 5.00;
    [P_load, load_time] = generate_load_profile(params);
    P_load = scale_to_monthly_bill(P_load, params);
    [sunny_pv, sunny_time] = generate_pv_profile(params);
    [cloudy_pv, cloudy_time] = cloudy_profile_1(params);
    assert(isequal(load_time, sunny_time, cloudy_time), ...
        'prepare_household_baseline:timeMismatch', ...
        'PV and load time vectors must match.');

    results.sunny = simulate_no_controller(sunny_pv, P_load, params, false);
    results.cloudy = simulate_no_controller(cloudy_pv, P_load, params, true);
    results.sunny.P_pv = sunny_pv;
    results.cloudy.P_pv = cloudy_pv;
    results.sunny.P_load = P_load;
    results.cloudy.P_load = P_load;
    results.sunny.time = load_time;
    results.cloudy.time = load_time;
    results.params = params;

    fprintf('\n===== Household Baseline: No Battery / No Controller =====\n');
    fprintf('Monthly household load: %.2f kWh\n', ...
        sum(P_load) * params.dt * params.billing_days);
    print_result('Sunny', results.sunny, params);
    print_result('Cloudy', results.cloudy, params);
end

function result = simulate_no_controller(P_pv, P_load, params, is_cloudy)
    [P_gimp, P_gexp, P_curt] = rule_based_ems(P_pv, P_load, params);
    validation = validate_power_balance( ...
        P_pv, P_load, P_gimp, P_gexp, P_curt, params);
    [daily_cost, cost] = calculate_household_costs( ...
        P_gimp, P_gexp, params.dt, params, is_cloudy);
    result = struct('P_gimp', P_gimp, 'P_gexp', P_gexp, ...
        'P_curt', P_curt, 'validation', validation, 'cost', cost, ...
        'daily_cost', daily_cost, ...
        'monthly_cost', params.billing_days * daily_cost);
end

function P_load = scale_to_monthly_bill(P_load, params)
    target_daily_kWh = params.household_monthly_kWh / params.billing_days;
    profile_daily_kWh = sum(P_load) * params.dt;
    P_load = P_load * (target_daily_kWh / profile_daily_kWh);
end

function [daily_cost, cost] = calculate_household_costs( ...
        P_gimp, P_gexp, dt, params, is_cloudy)
    import_kWh = sum(P_gimp) * dt;
    export_kWh = sum(P_gexp) * dt;
    monthly_import = import_kWh * params.billing_days;
    monthly_export = export_kWh * params.billing_days;
    billable_kWh = max(monthly_import - monthly_export, 0);
    if is_cloudy
        net_energy_rate = 3.21;
    else
        net_energy_rate = 6.75;
    end
    energy_cost_monthly = billable_kWh * net_energy_rate;
    fixed_cost_monthly = 70 * params.connected_load_kW;
    monthly_cost = energy_cost_monthly + fixed_cost_monthly;
    daily_cost = monthly_cost / params.billing_days;
    cost = struct('E_gimp', import_kWh, 'E_gexp', export_kWh, ...
        'energy_cost', energy_cost_monthly, ...
        'export_compensation', 0, 'total_cost', daily_cost, ...
        'billable_kWh', billable_kWh);
end

function print_result(name, result, params)
    fprintf('%s: PV %.2f kWh/day, import %.2f kWh/day, export %.2f kWh/day, ', ...
        name, sum(result.P_pv) * params.dt, result.cost.E_gimp, ...
        result.cost.E_gexp);
    fprintf('monthly bill Rs%.2f\n', result.monthly_cost);
end
