function [total_cost, cost_results] = calculate_costs(P_gimp, P_gexp, dt)
%CALCULATE_COSTS Calculate monthly import cost, export compensation, and bill.
%
%   The imported energy is assigned chronologically to the tariff's monthly
%   slabs. Each timestep's slab rate is multiplied by its APDCL ToD rate.

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
    E_gimp = sum(E_gimp_profile);
    E_gexp = sum(E_gexp_profile);

    slab_energy = allocate_monthly_slabs(E_gimp_profile, tariff.slab_limits_kWh);
    tod_multiplier = build_tod_multiplier(numel(P_gimp), dt, tariff.tod);
    import_rate = slab_energy.rate .* tod_multiplier;
    gross_energy_cost = sum(slab_energy.cost .* tod_multiplier);
    export_compensation = E_gexp * tariff.export_compensation_rate;

    if tariff.net_metering
        % Treat this 24-hour profile as a representative billing day:
        % exported energy offsets imported energy before billing.
        net_energy = max(E_gimp - E_gexp, 0);
        net_rate = mean(tariff.slab_effective_rates(1) * tod_multiplier);
        energy_cost = net_energy * net_rate;
        export_compensation = 0;
    else
        energy_cost = gross_energy_cost;
    end

    fixed_charge_daily = tariff.fixed_charge / 30;
    total_cost = tariff.billing_scale * ...
        (energy_cost - export_compensation + fixed_charge_daily);

    cost_results = struct('E_gimp', E_gimp, 'E_gexp', E_gexp, ...
        'energy_cost', energy_cost, ...
        'export_compensation', export_compensation, ...
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