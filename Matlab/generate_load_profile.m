function [P_load, time_vec] = generate_load_profile(params)
%GENERATE_LOAD_PROFILE Deterministic synthetic 24-hour load profile.

    time_vec = (0:params.N-1) * params.dt;
    P_base = 0.5;

    gauss = @(t, A, mu, sigma) A * exp(-((t - mu).^2) / (2*sigma^2));
    P_load = P_base + ...
        gauss(time_vec, 2.0, 8.0, 1.2) + ...
        gauss(time_vec, 2.8, 19.5, 1.5);
    P_load = max(P_load, 0);

    if max(P_load) > params.P_grid_imp_max
        error('generate_load_profile:designConstraintViolated', ...
            ['Synthetic load profile violates P_load_max <= ', ...
             'P_grid_imp_max (%.3f kW > %.3f kW).'], ...
            max(P_load), params.P_grid_imp_max);
    end
end