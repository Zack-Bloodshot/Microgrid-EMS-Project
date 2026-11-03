function sweep = run_alpha_sweep(alphas, make_plot)
%RUN_ALPHA_SWEEP Solve Phase 3 across a vector of degradation weights.
%
%   sweep = RUN_ALPHA_SWEEP() uses the default grid
%       [0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3, 5].
%
%   sweep = RUN_ALPHA_SWEEP(alphas) uses a caller-supplied vector.
%   sweep = RUN_ALPHA_SWEEP(alphas, false) skips the PNG plot (used by
%   verify_phase3 so verification needs no generated files).
%
%   For every alpha the function records physical costs (grid + actual
%   DoD-aware degradation), EFC, final SOC, curtailment, the solver
%   objective, and the validation status. It prints a formatted trade-off
%   table and saves a 2x2 figure to General Notes/assets.
%
%   Knee definition: the smallest alpha at which
%       EFC <= 0.5 * EFC(alpha = 0).
%   sweep.knee_alpha is NaN if no alpha qualifies.

    if nargin < 1 || isempty(alphas)
        alphas = [0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3, 5];
    end
    if nargin < 2 || isempty(make_plot)
        make_plot = true;
    end

    phase_dir  = fileparts(mfilename('fullpath'));
    matlab_dir = fileparts(phase_dir);
    addpath(matlab_dir, ...
        fullfile(matlab_dir, 'Phase2'), ...
        fullfile(matlab_dir, 'Phase3'));

    params = system_params();
    tariff = tariff_params();
    [P_pv, ~]   = generate_pv_profile(params);
    [P_load, ~] = generate_load_profile(params);

    n_alpha = numel(alphas);
    grid_cost   = zeros(1, n_alpha);
    deg_cost    = zeros(1, n_alpha);
    total_cost  = zeros(1, n_alpha);
    efc         = zeros(1, n_alpha);
    soc_end     = zeros(1, n_alpha);
    curt_energy = zeros(1, n_alpha);
    objective   = zeros(1, n_alpha);
    valid       = false(1, n_alpha);

    for i = 1:n_alpha
        [P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, g, d, obj] = ...
            lp_degradation_aware_ems(P_pv, P_load, tariff, params, alphas(i));
        report = validate_phase3_solution(P_pv, P_load, P_ch, P_dis, ...
            P_gimp, P_gexp, SOC, P_curt, params, false);

        [~, EFC] = battery_degradation_dod(P_ch, P_dis, params);

        grid_cost(i)   = g;
        deg_cost(i)    = d;
        total_cost(i)  = g + d;
        efc(i)         = EFC;
        soc_end(i)     = SOC(end);
        curt_energy(i) = sum(P_curt) * params.dt;
        objective(i)   = obj;
        valid(i)       = report.all_checks_passed;
    end

    % Knee: first alpha where EFC has dropped to at most half of EFC(0).
    efc0 = efc(alphas == 0, 1);
    if isempty(efc0)
        efc0 = efc(1);
    end
    knee_index = find(efc <= 0.5 * efc0, 1, 'first');
    if isempty(knee_index)
        knee_alpha = NaN;
    else
        knee_alpha = alphas(knee_index);
    end

    sweep = struct( ...
        'alpha', alphas, 'grid_cost', grid_cost, 'deg_cost', deg_cost, ...
        'total_cost', total_cost, 'EFC', efc, 'SOC_end', soc_end, ...
        'curt_energy', curt_energy, 'objective_value', objective, ...
        'validation_ok', valid, 'knee_alpha', knee_alpha, ...
        'degradation_model', sprintf('DoD %.0f%%, %d cycles', ...
            100*params.DoD_rated, params.N_cycles_rated));

    print_sweep(sweep);

    if make_plot
        save_sweep_plot(sweep, phase_dir);
    end
end

function print_sweep(sweep)
    fprintf('\n');
    fprintf('===============================================================================\n');
    fprintf(' Phase 3 Alpha Sweep - %s\n', sweep.degradation_model);
    fprintf('===============================================================================\n');
    fprintf(' %-7s %10s %10s %10s %8s %8s %9s %7s\n', ...
        'alpha', 'Grid', 'Degr.', 'Total', 'EFC', 'SOC_end', 'Curt.', 'Valid');
    fprintf(' %-7s %10s %10s %10s %8s %8s %9s %7s\n', ...
        '[-]', '[Rs/day]', '[Rs/day]', '[Rs/day]', '[-]', '[-]', '[kWh]', '');
    fprintf('-------------------------------------------------------------------------------\n');
    for i = 1:numel(sweep.alpha)
        fprintf(' %-7.2f %10.2f %10.2f %10.2f %8.3f %8.3f %9.3f %7s\n', ...
            sweep.alpha(i), sweep.grid_cost(i), sweep.deg_cost(i), ...
            sweep.total_cost(i), sweep.EFC(i), sweep.SOC_end(i), ...
            sweep.curt_energy(i), pass_fail(sweep.validation_ok(i)));
    end
    fprintf('-------------------------------------------------------------------------------\n');
    fprintf(' Knee (EFC <= 0.5 x EFC(alpha=0)) : ');
    if isnan(sweep.knee_alpha)
        fprintf('not reached in this sweep\n');
    else
        fprintf('alpha = %.2f\n', sweep.knee_alpha);
    end
    fprintf(' Reported costs are always physical: grid + actual degradation.\n');
    fprintf('===============================================================================\n\n');
end

function save_sweep_plot(sweep, phase_dir)
    project_root = fileparts(fileparts(phase_dir));
    assets_dir = fullfile(project_root, 'General Notes', 'assets');
    if ~exist(assets_dir, 'dir')
        mkdir(assets_dir);
    end

    fig = figure('Visible', 'off', 'Position', [100, 100, 1000, 750]);

    subplot(2,2,1);
    plot(sweep.alpha, sweep.grid_cost, 'o-', 'LineWidth', 1.6); grid on;
    xlabel('\alpha [-]'); ylabel('Grid cost [Rs/day]');
    title('Grid Cost vs. \alpha');

    subplot(2,2,2);
    plot(sweep.alpha, sweep.deg_cost, 'o-', 'LineWidth', 1.6); grid on;
    xlabel('\alpha [-]'); ylabel('Degradation cost [Rs/day]');
    title('Battery Wear vs. \alpha');

    subplot(2,2,3);
    plot(sweep.alpha, sweep.total_cost, 'o-', 'LineWidth', 1.6); grid on;
    xlabel('\alpha [-]'); ylabel('Total cost [Rs/day]');
    title('Total Physical Cost vs. \alpha');

    subplot(2,2,4);
    plot(sweep.alpha, sweep.EFC, 'o-', 'LineWidth', 1.6); grid on;
    xlabel('\alpha [-]'); ylabel('EFC [-]');
    title('Equivalent Full Cycles vs. \alpha');

    sgtitle(sprintf('Phase 3 Trade-off: %s', sweep.degradation_model));

    out_path = fullfile(assets_dir, 'phase3-alpha-sweep.png');
    print(fig, '-dpng', '-r150', out_path);
    close(fig);
    fprintf(' Saved alpha-sweep figure: %s\n\n', out_path);
end

function s = pass_fail(flag)
    if flag
        s = 'PASS';
    else
        s = 'FAIL';
    end
end
