function [P_pv, time_vec] = generate_pv_profile(params)
%GENERATE_PV_PROFILE Deterministic synthetic 24-hour PV profile.

    time_vec = (0:params.N-1) * params.dt;
    t_sunrise = 6;
    t_sunset  = 18;
    daylight = (time_vec > t_sunrise) & (time_vec < t_sunset);

    P_pv = zeros(1, params.N);
    shape = 0.5 * (1 - cos(2*pi*(time_vec(daylight) - t_sunrise) / ...
        (t_sunset - t_sunrise)));
    P_pv(daylight) = params.Ppv_rated * shape .^ 1.5;
    P_pv = min(max(P_pv, 0), params.Ppv_rated);
end