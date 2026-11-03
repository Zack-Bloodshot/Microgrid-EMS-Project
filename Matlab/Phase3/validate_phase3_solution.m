function report = validate_phase3_solution(P_pv, P_load, P_ch, P_dis, ...
    P_gimp, P_gexp, SOC, P_curt, params, verbose)
%VALIDATE_PHASE3_SOLUTION Post-simulation validation of the Phase 3 LP EMS.
%
%   report = VALIDATE_PHASE3_SOLUTION(P_pv, P_load, P_ch, P_dis, ...
%            P_gimp, P_gexp, SOC, P_curt, params)
%   performs the same physical checks as the Phase 2 validator, plus a
%   terminal-SOC check that SOC(N+1) >= params.SOC0.
%
%   Phase 2's validate_lp_solution.m is intentionally left untouched.
%
%   Output fields mirror the Phase 2 report where possible:
%     .residual, .max_residual, .residual_ok
%     .soc_ok, .soc_violations
%     .ch_limit_ok, .dis_limit_ok
%     .gimp_limit_ok, .gexp_limit_ok
%     .curt_limit_ok
%     .no_simultaneous_ok, .simultaneous_indices
%     .terminal_soc_ok, .terminal_soc
%     .degradation_model
%     .all_checks_passed
%
%   A formatted PASS/FAIL table is printed to the command window unless
%   the optional sixth argument `verbose` is false.

    if nargin < 10 || isempty(verbose)
        verbose = true;
    end

    N = params.N;
    tol = params.residual_tol;
    soc_tol = params.bound_tol;

    P_pv   = P_pv(:).';
    P_load = P_load(:).';

    %% Power balance
    residual = abs(P_gimp - P_gexp + P_dis - P_ch - P_curt - P_load + P_pv);
    report.residual     = residual;
    report.max_residual = max(residual);
    report.residual_ok  = all(residual < tol);

    %% SOC bounds
    soc_violations = find(SOC < params.SOC_min - soc_tol | ...
                          SOC > params.SOC_max + soc_tol);
    report.soc_violations = soc_violations;
    report.soc_ok = isempty(soc_violations);

    %% Battery and grid limits
    report.ch_limit_ok  = all(P_ch  >= -soc_tol & P_ch  <= params.P_ch_max  + soc_tol);
    report.dis_limit_ok = all(P_dis >= -soc_tol & P_dis <= params.P_dis_max + soc_tol);
    report.gimp_limit_ok = all(P_gimp >= -soc_tol & P_gimp <= params.P_grid_imp_max + soc_tol);
    report.gexp_limit_ok = all(P_gexp >= -soc_tol & P_gexp <= params.P_grid_exp_max + soc_tol);

    %% Curtailment
    report.curt_limit_ok = all(P_curt >= -soc_tol & P_curt <= P_pv + soc_tol);

    %% No simultaneous charge/discharge
    simultaneous = (P_ch > soc_tol) & (P_dis > soc_tol);
    report.no_simultaneous_ok = ~any(simultaneous);
    report.simultaneous_indices = find(simultaneous);

    %% Terminal SOC
    report.terminal_soc = SOC(end);
    report.terminal_soc_ok = SOC(end) >= params.SOC0 - soc_tol;

    %% Provenance
    report.degradation_model = sprintf('DoD %.0f%%, %d cycles', ...
        100*params.DoD_rated, params.N_cycles_rated);

    %% Overall pass/fail
    report.all_checks_passed = report.residual_ok && report.soc_ok && ...
        report.ch_limit_ok && report.dis_limit_ok && ...
        report.gimp_limit_ok && report.gexp_limit_ok && ...
        report.curt_limit_ok && report.no_simultaneous_ok && ...
        report.terminal_soc_ok;

    %% Formatted summary
    if ~verbose
        return;
    end

    fprintf('\n');
    fprintf('==================================================================\n');
    fprintf(' Phase 3 Validation - DoD-aware LP  (N = %d, model: %s)\n', ...
        N, report.degradation_model);
    fprintf('==================================================================\n');
    fprintf(' %-32s %-8s %s\n', 'Check', 'Result', 'Detail');
    fprintf(' -----------------------------------------------------------------\n');
    row('Power balance residual', report.residual_ok, ...
        sprintf('max %.2e kW (tol %.0e)', report.max_residual, tol));
    row(sprintf('SOC within [%.2f, %.2f]', params.SOC_min, params.SOC_max), ...
        report.soc_ok, violation_detail(report.soc_violations));
    row(sprintf('P_ch within [0, %.1f] kW', params.P_ch_max), ...
        report.ch_limit_ok, '');
    row(sprintf('P_dis within [0, %.1f] kW', params.P_dis_max), ...
        report.dis_limit_ok, '');
    row(sprintf('P_gimp within [0, %.1f] kW', params.P_grid_imp_max), ...
        report.gimp_limit_ok, '');
    row(sprintf('P_gexp within [0, %.1f] kW', params.P_grid_exp_max), ...
        report.gexp_limit_ok, '');
    row('P_curt within [0, P_pv(k)]', report.curt_limit_ok, '');
    row('No simultaneous ch/dis', report.no_simultaneous_ok, ...
        violation_detail(report.simultaneous_indices));
    row(sprintf('Terminal SOC >= %.3f', params.SOC0), ...
        report.terminal_soc_ok, sprintf('SOC(end) = %.3f', report.terminal_soc));
    fprintf(' -----------------------------------------------------------------\n');
    row('OVERALL', report.all_checks_passed, '');
    fprintf('==================================================================\n\n');
end

function row(label, flag, detail)
    if flag
        status = 'PASS';
    else
        status = 'FAIL';
    end
    if isempty(detail)
        fprintf(' %-32s %-8s\n', label, status);
    else
        fprintf(' %-32s %-8s %s\n', label, status, detail);
    end
end

function text = violation_detail(indices)
    if isempty(indices)
        text = '';
    else
        text = sprintf('%d violation(s)', numel(indices));
    end
end
