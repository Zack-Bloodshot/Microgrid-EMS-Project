function tod_multiplier = get_tod_multiplier(N, dt, tod)
%GET_TOD_MULTIPLIER Build the Time-of-Day price multiplier vector.
%
%   tod_multiplier = get_tod_multiplier(N, dt, tod) returns a [1 x N] vector
%   of ToD multipliers for N timesteps of duration dt [h], based on the
%   tod struct from tariff_params().
%
%   This is the single source of truth for ToD multiplier logic, shared by
%   calculate_costs.m and build_lp_price_vectors.m.
%
%   Inputs:
%     N   - number of timesteps in the horizon
%     dt  - [h] timestep duration
%     tod - struct with fields: normal_multiplier, solar_multiplier,
%           peak_multiplier, solar_hours [start, end], peak_hours [start, end]
%
%   Output:
%     tod_multiplier - [1 x N] ToD multiplier at each timestep
%
%   See also: calculate_costs, build_lp_price_vectors, tariff_params.

    time_vec = (0:N-1) * dt;
    tod_multiplier = tod.normal_multiplier * ones(1, N);
    solar_hours = time_vec >= tod.solar_hours(1) & time_vec < tod.solar_hours(2);
    peak_hours = time_vec >= tod.peak_hours(1) & time_vec < tod.peak_hours(2);
    tod_multiplier(solar_hours) = tod.solar_multiplier;
    tod_multiplier(peak_hours) = tod.peak_multiplier;
end
