function [P_load, time_vec] = generate_load_profile(params)
%GENERATE_LOAD_PROFILE Deterministic synthetic 24-hour load profile.
%
% Includes morning, afternoon and evening demand peaks so that
% the Phase 1 greedy EMS and Phase 2 cost-optimized EMS
% exhibit a meaningful difference in battery scheduling.

    time_vec = (0:params.N-1) * params.dt;



    % Gaussian load components
    gauss = @(t, A, mu, sigma) ...
        A * exp(-((t - mu).^2) / (2*sigma^2));

% Load profile:
% Morning peak     : 08:00
% Afternoon peak   : 16:15
% Evening peak     : 19:30
% Scaled to represent a solar-equipped single-family daily demand.
P_base = 0.264;

P_load = P_base + ...
    gauss(time_vec, 0.792, 8.0, 1.2) + ...
    gauss(time_vec, 1.76, 16.25, 0.75) + ...
    gauss(time_vec, 1.32, 19.5, 1.5);

    P_load = max(P_load, 0);

    % Check against maximum grid-import capability
    if max(P_load) > params.P_grid_imp_max
        error('generate_load_profile:designConstraintViolated', ...
            ['Synthetic load profile violates P_load_max <= ', ...
             'P_grid_imp_max (%.3f kW > %.3f kW).'], ...
             max(P_load), params.P_grid_imp_max);
    end
end