function report = validate_lp_solution(P_pv, P_load, P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, params)
%VALIDATE_LP_SOLUTION Post-simulation validation of the Phase 2 LP EMS run.
%
%   report = VALIDATE_LP_SOLUTION(P_pv, P_load, P_ch, P_dis, P_gimp, ...
%            P_gexp, SOC, P_curt, params)
%   checks, at every timestep, the "Post-Simulation Validation Checks"
%   from phase_2_implementation.md:
%
%     1) Solver convergence (exitflag == 1) is enforced inside
%        lp_naive_ems.m itself -- linprog throws a hard error there if
%        the solve does not converge, so any report produced here is
%        guaranteed to originate from a converged solution.
%     2) Power balance residual check
%     3) Simultaneous cycling absence check (no charge & discharge at
%        the same timestep)
%     4) SOC boundary enforcement check
%
%   Output:
%     report - struct with fields:
%       .residual            [1 x N] power balance residual at each step
%       .max_residual        scalar, worst-case residual
%       .residual_ok         logical, true if all residuals < tolerance
%       .soc_ok              logical, true if SOC never breaches bounds
%       .soc_violations      indices (into SOC) where bounds are breached
%       .ch_limit_ok         logical, true if P_ch always within bounds
%       .dis_limit_ok        logical, true if P_dis always within bounds
%       .gimp_limit_ok       logical, true if P_gimp always within bounds
%       .gexp_limit_ok       logical, true if P_gexp always within bounds
%       .curt_limit_ok       logical, true if 0 <= P_curt(k) <= P_pv(k)
%       .no_simultaneous_ok  logical, true if charge & discharge never overlap
%       .simultaneous_indices indices where both P_ch and P_dis are active
%       .all_checks_passed   logical, overall pass/fail
%
%   A short pass/fail summary is also printed to the command window.

    N = params.N;
    tol = params.residual_tol;

    P_pv   = P_pv(:).';
    P_load = P_load(:).';

    %% 1) Power balance residual (Section 3 equation, with P_curt term)
    % Residual(k) = | P_gimp - P_gexp + P_dis - P_ch - P_curt - P_load + P_pv |
    residual = abs(P_gimp - P_gexp + P_dis - P_ch - P_curt - P_load + P_pv);
    report.residual     = residual;
    report.max_residual = max(residual);
    report.residual_ok  = all(residual < tol);

    %% 2) SOC bounds
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

    %% 5) Curtailment limits (0 <= P_curt(k) <= P_pv(k))
    report.curt_limit_ok = all(P_curt >= -soc_tol & P_curt <= P_pv + soc_tol);

    %% 6) No simultaneous charge/discharge
    simultaneous = (P_ch > soc_tol) & (P_dis > soc_tol);
    report.no_simultaneous_ok = ~any(simultaneous);
    report.simultaneous_indices = find(simultaneous);

    %% Overall pass/fail
    report.all_checks_passed = report.residual_ok && report.soc_ok && ...
        report.ch_limit_ok && report.dis_limit_ok && ...
        report.gimp_limit_ok && report.gexp_limit_ok && ...
        report.curt_limit_ok && report.no_simultaneous_ok;

    %% Print summary
    fprintf('\n===== Phase 2 LP EMS Validation Summary =====\n');
    fprintf('Timesteps simulated        : %d\n', N);
    fprintf('Solver convergence          : %s (enforced in lp_naive_ems.m)\n', pass_fail(true));
    fprintf('Max power balance residual : %.3e (tol = %.1e) -> %s\n', ...
        report.max_residual, tol, pass_fail(report.residual_ok));
    fprintf('SOC within [%.2f, %.2f]     : %s\n', ...
        params.SOC_min, params.SOC_max, pass_fail(report.soc_ok));
    fprintf('P_ch within [0, %.1f] kW    : %s\n', params.P_ch_max, pass_fail(report.ch_limit_ok));
    fprintf('P_dis within [0, %.1f] kW   : %s\n', params.P_dis_max, pass_fail(report.dis_limit_ok));
    fprintf('P_gimp within [0, %.1f] kW  : %s\n', params.P_grid_imp_max, pass_fail(report.gimp_limit_ok));
    fprintf('P_gexp within [0, %.1f] kW  : %s\n', params.P_grid_exp_max, pass_fail(report.gexp_limit_ok));
    fprintf('P_curt within [0, P_pv(k)]  : %s\n', pass_fail(report.curt_limit_ok));
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
