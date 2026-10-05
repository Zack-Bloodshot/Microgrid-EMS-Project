function report = validate_power_balance(P_pv, P_load, P_gimp, P_gexp, P_curt, params)
%VALIDATE_POWER_BALANCE Validate Phase 0 balance and operating limits.

    tol = params.residual_tol;
    residual = abs(P_gimp - P_gexp - P_load + P_pv - P_curt);

    report.residual = residual;
    report.max_residual = max(residual);
    report.residual_ok = all(residual < tol);
    report.gimp_limit_ok = all(P_gimp >= -tol & ...
        P_gimp <= params.P_grid_imp_max + tol);
    report.gexp_limit_ok = all(P_gexp >= -tol & ...
        P_gexp <= params.P_grid_exp_max + tol);
    report.all_checks_passed = report.residual_ok && ...
        report.gimp_limit_ok && report.gexp_limit_ok;

    fprintf('\n===== Phase 0 EMS Validation Summary =====\n');
    fprintf('Timesteps simulated        : %d\n', params.N);
    fprintf('Max power balance residual : %.3e -> %s\n', ...
        report.max_residual, pass_fail(report.residual_ok));
    fprintf('Grid import within limit   : %s\n', pass_fail(report.gimp_limit_ok));
    fprintf('Grid export within limit   : %s\n', pass_fail(report.gexp_limit_ok));
    fprintf('OVERALL RESULT              : %s\n', pass_fail(report.all_checks_passed));
    fprintf('============================================\n\n');
end

function text = pass_fail(flag)
    if flag
        text = 'PASS';
    else
        text = 'FAIL';
    end
end