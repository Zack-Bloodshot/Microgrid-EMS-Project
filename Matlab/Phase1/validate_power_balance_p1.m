function report = validate_power_balance_p1(P_pv, P_load, P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, params)
%VALIDATE_POWER_BALANCE Post-simulation validation of the Phase 1 EMS run.
%
%   report = VALIDATE_POWER_BALANCE(P_pv, P_load, P_ch, P_dis, P_gimp, ...
%            P_gexp, SOC, P_curt, params)
%   checks, at every timestep:
%     1) Power balance residual (Section 5 of the documentation)
%     2) SOC stays within [SOC_min, SOC_max]
%     3) Battery charge/discharge power stays within [0, P_ch_max] /
%        [0, P_dis_max]
%     4) Grid import/export power stays within [0, P_grid_imp_max] /
%        [0, P_grid_exp_max]
%     5) No simultaneous battery charging and discharging at the same
%        timestep
%
%   Output:
%     report - struct with fields:
%       .residual         [1 x N] power balance residual at each step
%       .max_residual     scalar, worst-case residual
%       .residual_ok      logical, true if all residuals < tolerance
%       .soc_ok           logical, true if SOC never breaches bounds
%       .soc_violations   indices (into SOC) where bounds are breached
%       .ch_limit_ok      logical, true if P_ch always within bounds
%       .dis_limit_ok     logical, true if P_dis always within bounds
%       .gimp_limit_ok    logical, true if P_gimp always within bounds
%       .gexp_limit_ok    logical, true if P_gexp always within bounds
%       .no_simultaneous_ok logical, true if charge & discharge never overlap
%       .all_checks_passed logical, overall pass/fail
%
%   A short pass/fail summary is also printed to the command window.

    N = params.N;
    tol = params.residual_tol;

    %% 1) Power balance residual
    % Residual(k) = | P_gimp - P_gexp + P_dis - P_ch - P_load + P_pv - P_curt |
    residual = abs(P_gimp - P_gexp + P_dis - P_ch - P_load + P_pv - P_curt);
    report.residual     = residual;
    report.max_residual = max(residual);
    report.residual_ok  = all(residual < tol);

    %% 2) SOC bounds
    % Allow a tiny numerical tolerance on the bound check itself
    soc_tol = 1e-9;
    soc_violations = find(SOC < params.SOC_min - soc_tol | SOC > params.SOC_max + soc_tol);
    report.soc_violations = soc_violations;
    report.soc_ok = isempty(soc_violations);

    %% 3) Battery power limits
    report.ch_limit_ok  = all(P_ch  >= -soc_tol & P_ch  <= params.P_ch_max  + soc_tol);
    report.dis_limit_ok = all(P_dis >= -soc_tol & P_dis <= params.P_dis_max + soc_tol);

    %% 4) Grid power limits
    report.gimp_limit_ok = all(P_gimp >= -soc_tol & P_gimp <= params.P_grid_imp_max + soc_tol);
    report.gexp_limit_ok = all(P_gexp >= -soc_tol & P_gexp <= params.P_grid_exp_max + soc_tol);

    %% 5) No simultaneous charge/discharge
    simultaneous = (P_ch > soc_tol) & (P_dis > soc_tol);
    report.no_simultaneous_ok = ~any(simultaneous);
    report.simultaneous_indices = find(simultaneous);

    %% Overall pass/fail
    report.all_checks_passed = report.residual_ok && report.soc_ok && ...
        report.ch_limit_ok && report.dis_limit_ok && ...
        report.gimp_limit_ok && report.gexp_limit_ok && ...
        report.no_simultaneous_ok;

    %% Print summary
    fprintf('\n===== Phase 1 EMS Validation Summary =====\n');
    fprintf('Timesteps simulated        : %d\n', N);
    fprintf('Max power balance residual : %.3e (tol = %.1e) -> %s\n', ...
        report.max_residual, tol, pass_fail(report.residual_ok));
    fprintf('SOC within [%.2f, %.2f]     : %s\n', ...
        params.SOC_min, params.SOC_max, pass_fail(report.soc_ok));
    fprintf('P_ch within [0, %.1f] kW    : %s\n', params.P_ch_max, pass_fail(report.ch_limit_ok));
    fprintf('P_dis within [0, %.1f] kW   : %s\n', params.P_dis_max, pass_fail(report.dis_limit_ok));
    fprintf('P_gimp within [0, %.1f] kW  : %s\n', params.P_grid_imp_max, pass_fail(report.gimp_limit_ok));
    fprintf('P_gexp within [0, %.1f] kW  : %s\n', params.P_grid_exp_max, pass_fail(report.gexp_limit_ok));
    fprintf('No simultaneous ch/dis     : %s\n', pass_fail(report.no_simultaneous_ok));
    fprintf('--------------------------------------------\n');
    fprintf('OVERALL RESULT              : %s\n', pass_fail(report.all_checks_passed));
    fprintf('=============================================\n\n');

end

function s = pass_fail(flag)
%PASS_FAIL Helper to convert a logical into a readable PASS/FAIL string.
    if flag
        s = 'PASS';
    else
        s = 'FAIL';
    end
end
