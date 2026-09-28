function [P_load, time_vec] = generate_load_profile(params)
%GENERATE_LOAD_PROFILE Deterministic synthetic 24-hour load profile.
%
% Includes morning, afternoon and evening demand peaks so that
% the Phase 1 greedy EMS and Phase 2 cost-optimized EMS
% exhibit a meaningful difference in battery scheduling.

    time_vec = (0:params.N-1) * params.dt;

    % Base household demand
    P_base = 0.6;

    % Gaussian load components
    gauss = @(t, A, mu, sigma) ...
        A * exp(-((t - mu).^2) / (2*sigma^2));

    % Load profile:
    % Morning peak     : 08:00
    % Afternoon peak   : 14:30
    % Evening peak     : 19:30
    P_load = P_base + ...
        gauss(time_vec, 1.8, 8.0, 1.2) + ...
        gauss(time_vec, 2.2, 14.5, 0.9) + ...
        gauss(time_vec, 2.8, 19.5, 1.5);

    P_load = max(P_load, 0);

    % Check against maximum grid-import capability
    if max(P_load) > params.P_grid_imp_max
        error('generate_load_profile:designConstraintViolated', ...
            ['Synthetic load profile violates P_load_max <= ', ...
             'P_grid_imp_max (%.3f kW > %.3f kW).'], ...
             max(P_load), params.P_grid_imp_max);
    end
end