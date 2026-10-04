function [P_pv, time_vec] = cloudy_profile_1(params)
%CLOUDY_PROFILE_1 Cloudy day with attenuated, narrow midday generation.

    time_vec = (0:params.N-1) * params.dt;
    cloud_window = exp(-((time_vec - 12.5).^2) / (2 * 1.65^2));
    % Dense cloud cover limits the peak and shortens the useful PV window.
    P_pv = params.Ppv_rated * 0.60 * cloud_window .^ 1.15;
    P_pv = min(max(P_pv, 0), params.Ppv_rated);
end
