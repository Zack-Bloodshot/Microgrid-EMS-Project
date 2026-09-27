function [total_cost, cost_results] = calculate_costs(P_gimp, P_gexp, dt)
%CALCULATE_COSTS Calculate the monthly bill using 1:1 net metering.
%
%   Exported energy offsets imported energy before the net billable energy is
%   assigned chronologically to the tariff's monthly slabs and ToD rates.

    if ~isequal(size(P_gimp), size(P_gexp))
        error('calculate_costs:dimensionMismatch', ...
            'Grid import and export profiles must have the same dimensions.');
    end
    if ~isscalar(dt) || dt <= 0
        error('calculate_costs:invalidTimestep', 'dt must be positive.');
    end
    tariff = tariff_params();
    E_gimp_profile = P_gimp * dt;
    E_gexp_profile = P_gexp * dt;
    P_grid_net = P_gimp - P_gexp;
    E_grid_net = sum(P_grid_net) * dt;
    E_gimp = sum(E_gimp_profile);
    E_gexp = sum(E_gexp_profile);
    E_bill = max(E_grid_net, 0);

    positive_net_energy = max(P_grid_net, 0) * dt;
    positive_net_total = sum(positive_net_energy);
    if positive_net_total > 0
        billable_energy_profile = positive_net_energy * (E_bill / positive_net_total);
    else
        billable_energy_profile = zeros(size(P_grid_net));
    end

    slab_energy = allocate_monthly_slabs(billable_energy_profile, tariff.slab_limits_kWh);
    tod_multiplier = build_tod_multiplier(numel(P_gimp), dt, tariff.tod);
    import_rate = slab_energy.rate .* tod_multiplier;
    energy_cost = sum(slab_energy.cost .* tod_multiplier);
    total_cost = energy_cost;

    cost_results = struct('P_grid_net', P_grid_net, ...
        'E_gimp', E_gimp, 'E_gexp', E_gexp, 'E_grid_net', E_grid_net, ...
        'E_bill', E_bill, ...
        'energy_cost', energy_cost, ...
        'total_cost', total_cost, 'import_rate', import_rate, ...
        'slab_energy', slab_energy.energy);
end

function slab_energy = allocate_monthly_slabs(energy_profile, slab_limits)
    slab_energy.energy = zeros(size(energy_profile));
    slab_energy.rate = zeros(size(energy_profile));
    slab_energy.cost = zeros(size(energy_profile));
    slab_rates = tariff_params().slab_effective_rates;
    cumulative_energy = 0;

    for k = 1:numel(energy_profile)
        remaining = energy_profile(k);
        while remaining > 0
            slab_index = find(cumulative_energy < [slab_limits, inf], 1, 'first');
            if slab_index == 1
                slab_end = slab_limits(1);
            elseif slab_index <= numel(slab_limits)
                slab_end = slab_limits(slab_index);
            else
                slab_end = inf;
            end
            available = slab_end - cumulative_energy;
            allocated = min(remaining, available);
            slab_energy.energy(k) = slab_energy.energy(k) + allocated;
            slab_energy.rate(k) = slab_rates(slab_index);
            slab_energy.cost(k) = slab_energy.cost(k) + ...
                allocated * slab_rates(slab_index);
            cumulative_energy = cumulative_energy + allocated;
            remaining = remaining - allocated;
        end
    end
end

function tod_multiplier = build_tod_multiplier(N, dt, tod)
    time_vec = (0:N-1) * dt;
    tod_multiplier = tod.normal_multiplier * ones(1, N);
    solar_hours = time_vec >= tod.solar_hours(1) & time_vec < tod.solar_hours(2);
    peak_hours = time_vec >= tod.peak_hours(1) & time_vec < tod.peak_hours(2);
    tod_multiplier(solar_hours) = tod.solar_multiplier;
    tod_multiplier(peak_hours) = tod.peak_multiplier;
end