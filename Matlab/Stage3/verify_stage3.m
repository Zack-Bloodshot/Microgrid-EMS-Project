function verify_stage3()
%VERIFY_STAGE3 End-to-end verification for the Stage 3 degradation-aware EMS.
%
%   Also checks that Stage 1/2/3 share one degradation model.
%
%   Runs a fixed suite of checks and prints a formatted PASS/FAIL table.
%   Raises an error at the end if any check fails, so the function can be
%   used in a CI-like workflow without a MATLAB test framework.
%
%   Usage:
%       cd Matlab
%       startup
%       verify_stage3

    stage_dir  = fileparts(mfilename('fullpath'));
    matlab_dir = fileparts(stage_dir);
    addpath(matlab_dir, ...
        fullfile(matlab_dir, 'Stage0'), ...
        fullfile(matlab_dir, 'Stage1'), ...
        fullfile(matlab_dir, 'Stage2'), ...
        fullfile(matlab_dir, 'Stage3'));

    params = system_params();
    tariff = tariff_params();
    [P_pv, ~]   = generate_pv_profile(params);
    [P_load, ~] = generate_load_profile(params);
    [cloudy_pv, ~] = cloudy_profile_1(params);

    check_names = {};
    check_flags = [];
    check_notes = {};

    %% Shared runs
    sunny = simulate_day(P_pv, P_load, params, tariff, 1);
    sunny_zero = simulate_day(P_pv, P_load, params, tariff, 0);
    cloudy = simulate_day(cloudy_pv, P_load, params, tariff, 1);

    p2 = sunny.stage2;
    p3 = sunny.stage3;

    %% 1) Stage 2 regression (shared wear model, current parameters)
    p2_ok = abs(p2.grid_cost - 24.6857) < 1e-3 && ...
            abs(p2.degradation_cost - 26.0343) < 1e-3 && ...
            abs(p2.EFC - 0.801) < 1e-3;
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'Stage 2 baseline (shared model)', p2_ok, ...
        sprintf('grid %.4f, degr %.4f, EFC %.4f', ...
            p2.grid_cost, p2.degradation_cost, p2.EFC));

    %% 1b) Every stage reports the same degradation model
    same_model = strcmp(sunny.stage1.degradation_model, ...
        sunny.stage2.degradation_model) && ...
        strcmp(sunny.stage2.degradation_model, ...
        sunny.stage3.degradation_model);
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'All stages share one wear model', same_model, ...
        sunny.stage3.degradation_model);

    %% 2) Shared degradation model constants
    c_deg = params.Cost_replacement / ...
        (params.N_cycles_rated * 2 * params.E_B * params.DoD_rated);
    per_rated = params.Cost_replacement / params.N_cycles_rated;
    per_efc = params.Cost_replacement / ...
        (params.N_cycles_rated * params.DoD_rated);
    dm_ok = abs(params.DoD_rated - 0.80) < 1e-12 && ...
            abs(c_deg - 1.625) < 1e-3 && ...
            abs(per_rated - 26.0) < 1e-3 && ...
            abs(per_efc - 32.5) < 1e-3;
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'Shared degradation constants', dm_ok, ...
        sprintf('DoD %.2f, %.4f Rs/kWh, %.2f Rs/cycle', ...
            params.DoD_rated, c_deg, per_rated));

    %% 3) Alpha-zero grid equivalence
    a0_ok = abs(sunny_zero.stage3.grid_cost - p2.grid_cost) < 1e-6;
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'alpha = 0 matches Stage 2 grid cost', a0_ok, ...
        sprintf('diff %.2e Rs', ...
            abs(sunny_zero.stage3.grid_cost - p2.grid_cost)));

    %% 4) Terminal SOC for every Stage 3 run
    runs = {sunny.stage3, sunny_zero.stage3, cloudy.stage3};
    run_labels = {'sunny a=1', 'sunny a=0', 'cloudy a=1'};
    term_ok = true;
    term_detail = '';
    for i = 1:numel(runs)
        ok = runs{i}.SOC(end) >= params.SOC0 - 1e-9;
        term_ok = term_ok && ok;
        if ~ok
            term_detail = sprintf('%s: SOC(end)=%.4f; ', ...
                run_labels{i}, runs{i}.SOC(end));
        end
    end
    if isempty(term_detail)
        term_detail = sprintf('min SOC(end) = %.4f', ...
            min(cellfun(@(r) r.SOC(end), runs)));
    end
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'Terminal SOC >= SOC0', term_ok, term_detail);

    %% 5) Power balance for every Stage 3 run
    pb_ok = true;
    pb_max = 0;
    for i = 1:numel(runs)
        pb_max = max(pb_max, runs{i}.validation.max_residual);
        pb_ok = pb_ok && runs{i}.validation.residual_ok;
    end
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'Power balance residual', pb_ok, ...
        sprintf('max %.2e kW', pb_max));

    %% 6) Operating bounds
    bounds_ok = true;
    for i = 1:numel(runs)
        r = runs{i}.validation;
        bounds_ok = bounds_ok && r.soc_ok && r.ch_limit_ok && ...
            r.dis_limit_ok && r.gimp_limit_ok && r.gexp_limit_ok && ...
            r.curt_limit_ok;
    end
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'SOC / power / curtailment bounds', bounds_ok, ...
        'all Stage 3 runs');

    %% 7) No simultaneous charge/discharge
    sim_ok = true;
    for i = 1:numel(runs)
        sim_ok = sim_ok && runs{i}.validation.no_simultaneous_ok;
    end
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'No simultaneous charge/discharge', sim_ok, ...
        'all Stage 3 runs');

    %% 8) Cloudy case solves and validates
    cloudy_ok = cloudy.stage3.validation.all_checks_passed;
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'Cloudy profile solves and validates', cloudy_ok, ...
        sprintf('grid %.2f Rs, EFC %.3f', ...
            cloudy.stage3.grid_cost, cloudy.stage3.EFC));

    %% 9) Sweep sanity
    sweep = run_alpha_sweep([], false);
    tol = 1e-4;
    deg_mono = all(diff(sweep.deg_cost) <= tol);
    efc_mono = all(diff(sweep.EFC) <= tol);
    grid_mono = all(diff(sweep.grid_cost) >= -tol);
    sweep_ok = deg_mono && efc_mono && grid_mono && ...
        all(sweep.validation_ok);
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'Alpha sweep monotonic and valid', sweep_ok, ...
        sprintf('knee alpha = %s', num2str(sweep.knee_alpha)));

    %% 10) Cost consistency
    cost_ok = abs(p3.total_cost - (p3.grid_cost + p3.degradation_cost)) < 1e-9;
    [check_names, check_flags, check_notes] = add_check( ...
        check_names, check_flags, check_notes, ...
        'total_cost = grid + degradation', cost_ok, ...
        sprintf('%.4f Rs/day', p3.total_cost));

    %% Print table
    fprintf('\n');
    fprintf('===============================================================================\n');
    fprintf(' Stage 3 End-to-End Verification\n');
    fprintf('===============================================================================\n');
    fprintf(' %-42s %-7s %s\n', 'Check', 'Result', 'Detail');
    fprintf('-------------------------------------------------------------------------------\n');
    for i = 1:numel(check_names)
        fprintf(' %-42s %-7s %s\n', check_names{i}, ...
            pass_fail(check_flags(i)), check_notes{i});
    end
    fprintf('-------------------------------------------------------------------------------\n');
    overall = all(check_flags);
    fprintf(' %-42s %-7s\n', 'OVERALL', pass_fail(overall));
    fprintf('===============================================================================\n\n');

    if ~overall
        failed = check_names(~check_flags);
        error('verify_stage3:checkFailed', ...
            'Stage 3 verification failed: %s', strjoin(failed, ', '));
    end
end

function [names, flags, notes] = add_check(names, flags, notes, name, flag, note)
    names{end+1} = name;
    flags(end+1) = logical(flag);
    notes{end+1} = note;
end

function s = pass_fail(flag)
    if flag
        s = 'PASS';
    else
        s = 'FAIL';
    end
end
