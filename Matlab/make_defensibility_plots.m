function make_defensibility_plots()
%MAKE_DEFENSIBILITY_PLOTS Render figures for the Defensibility Analysis note.

outdir = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
    'General Notes', 'assets');
if ~exist(outdir, 'dir'); mkdir(outdir); end

p = system_params();
[~, ~] = generate_load_profile(p);

fig1_cost_breakdown(p, outdir);
fig2_sensitivity(p, outdir);
fig3_literature(p, outdir);
fig4_soc_timing(p, outdir);
fig5_breakeven(p, outdir);
fprintf('\nPlots written to: %s\n', outdir);
end

% ---------- 1. Cost breakdown: grid vs degradation ----------
function fig1_cost_breakdown(p, outdir)
[pp, ~] = generate_pv_profile(p); [pl, ~] = generate_load_profile(p);
r = simulate_day(pp, pl, p, tariff_params());
g = [r.stage0.grid_cost, r.stage1.grid_cost, r.stage2.grid_cost];
d = [r.stage0.degradation_cost, r.stage1.degradation_cost, r.stage2.degradation_cost];

f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 520]);
bar([g(:), d(:)], 'stacked'); grid on;
set(gca, 'XTickLabel', {'Stage 0\nBaseline', 'Stage 1\nHeuristic', 'Stage 2\nLP'});
ylabel('Daily cost [Rs/day]'); ylim([0 75]);
legend('Grid energy cost', 'Battery degradation', 'Location', 'northwest');
title({'Daily cost breakdown (sunny day)', ...
    'Degradation priced at Rs 32.50 per equivalent full cycle (80% DoD, 5000 cycles)'});
print(f, fullfile(outdir, 'cost-breakdown.png'), '-dpng', '-r150'); close(f);
end

% ---------- 2. Sensitivity: LP vs heuristic gap ----------
function fig2_sensitivity(p, outdir)
names = {'Export rate', 'Load scale', 'Battery size', 'ToD peak mult.', 'PV availability'};
gap   = zeros(1, 5); base_gap = zeros(1, 5);
sets = { ...
    [0 2 4 6.75], [0.85 1.0 1.15 1.3], [5 10 15 20], [1.0 1.2 1.6 2.0], [0.3 0.5 0.7 1.0]};
for i = 1:5
    g = zeros(1, numel(sets{i}));
    for j = 1:numel(sets{i})
        v = sets{i}(j); ov = struct(); p2 = p; ls = 1; ps = 1;
        switch i
            case 1, ov = struct('export_rate', v);
            case 2, ls = v;
            case 3, p2.E_B = v;
            case 4, ov = struct('peak_multiplier', v);
            case 5, ps = v;
        end
        t = tariff_params(ov);
        pv = generate_pv_profile(p2) * ps; pl = generate_load_profile(p2) * ls;
        rr = simulate_day(pv, pl, p2, t);
        g(j) = rr.stage1.grid_cost - rr.stage2.grid_cost;   % abs, Rs/day
    end
    gap(i) = mean(g); base_gap(i) = 100 * mean(g) / 50.54;
end

f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 820 480]);
bar(gap); grid on; ylim([0 6]);
set(gca, 'XTickLabel', names); ylabel('LP advantage over heuristic [Rs/day]');
title({'LP advantage over greedy rule, averaged across each parameter sweep', ...
    '(grid cost only, sunny day, EFC-based degradation excluded)'});
for i = 1:5
    text(i, gap(i), sprintf(' %.2f', gap(i)), 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom');
end
print(f, fullfile(outdir, 'sensitivity-gap.png'), '-dpng', '-r150'); close(f);
end

% ---------- 3. Literature benchmark ----------
function fig3_literature(p, outdir)
[pp, ~] = generate_pv_profile(p); [pl, ~] = generate_load_profile(p);
t = tariff_params();
rS = simulate_day(pp, pl, p, t);
[cp, ~] = cloudy_profile_1(p);
rC = simulate_day(cp, pl, p, t);
gS = 100 * (rS.stage1.grid_cost - rS.stage2.grid_cost) / rS.stage1.grid_cost;
gC = 100 * (rC.stage1.grid_cost - rC.stage2.grid_cost) / rC.stage1.grid_cost;

f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 780 480]);
X = [11.17 14.80; gS gC];
bar(X, 'grouped'); grid on; ylim([0 20]);
set(gca, 'XTickLabel', {'Clear / sunny day', 'Cloudy day'});
ylabel('Heuristic cost premium over LP [%]');
legend({'Sarda et al. (IFAC 2022)', 'This project'}, 'Location', 'northwest');
title({'Optimisation gain vs. published benchmark', ...
    'Heuristic cost expressed as % premium over optimal'});
for i = 1:2
    text(i - 0.19, X(i,1), sprintf('%.2f', X(i,1)), 'HorizontalAlignment','center', ...
        'VerticalAlignment', 'bottom');
    text(i + 0.19, X(i,2), sprintf('%.2f', X(i,2)), 'HorizontalAlignment','center', ...
        'VerticalAlignment', 'bottom');
end
print(f, fullfile(outdir, 'literature-benchmark.png'), '-dpng', '-r150'); close(f);
end

% ---------- 4. SOC timing story ----------
function fig4_soc_timing(p, outdir)
[pp, tv] = generate_pv_profile(p); [pl, ~] = generate_load_profile(p);
r = simulate_day(pp, pl, p, tariff_params());
t = tariff_params();

f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 940 560]);
subplot(2,1,1);
plot(tv, pp, 'Color', [0.85 0.65 0.13], 'LineWidth', 1.6); hold on;
plot(tv, pl, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.6);
yl = [-1 3.5];
patch([9 17 17 9], [yl(1) yl(1) yl(2) yl(2)], [0.9 0.95 1.0], ...
    'FaceAlpha', 0.6, 'EdgeColor', 'none');
patch([17 22 22 17], [yl(1) yl(1) yl(2) yl(2)], [1.0 0.93 0.93], ...
    'FaceAlpha', 0.7, 'EdgeColor', 'none');
plot(tv, r.stage1.P_gimp, 'Color', [0.00 0.45 0.74], 'LineWidth', 1.4);
grid on; xlim([0 24]); ylim(yl);
xlabel('Time [h]'); ylabel('Power [kW]');
legend('P_{pv}', 'P_{load}', 'P_{g,imp} (heuristic)', 'Location', 'northwest');
title('Sunny day: PV, load and heuristic grid import');

subplot(2,1,2);
plot([tv, 24], r.stage1.SOC, 'LineWidth', 1.8, 'Color', [0.49 0.18 0.56]); hold on;
plot([tv, 24], r.stage2.SOC, 'LineWidth', 1.8, 'Color', [0.00 0.60 0.25]);
yl2 = [0 1];
patch([9 17 17 9], [yl2(1) yl2(1) yl2(2) yl2(2)], [0.9 0.95 1.0], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
patch([17 22 22 17], [yl2(1) yl2(1) yl2(2) yl2(2)], [1.0 0.93 0.93], 'FaceAlpha', 0.7, 'EdgeColor', 'none');
grid on; xlim([0 24]); ylim(yl2);
xlabel('Time [h]'); ylabel('SOC [-]');
legend('Heuristic', 'LP (optimised)', 'Location', 'east');
title('Battery SOC: heuristic drains early, LP reserves for the peak window');
print(f, fullfile(outdir, 'soc-timing.png'), '-dpng', '-r150'); close(f);
end

% ---------- 5. Break-even / payback ----------
function fig5_breakeven(p, outdir)
[pp, ~] = generate_pv_profile(p); [pl, ~] = generate_load_profile(p);
r = simulate_day(pp, pl, p, tariff_params());
cpl = p.Cost_replacement / (p.N_cycles_rated * p.DoD_rated);
annual_save = (r.stage0.grid_cost - r.stage2.grid_cost) * 365;
annual_deg   = r.stage2.EFC * cpl * 365;
years = 0:1:20;

f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 860 520]);
plot(years, annual_save * years, 'LineWidth', 2.2, 'Color', [0.00 0.55 0.25]); hold on;
plot(years, annual_deg * years, 'LineWidth', 2.2, 'Color', [0.75 0.20 0.15]);
plot(years, annual_save * years - annual_deg * years, 'LineWidth', 2.4, 'Color', [0.00 0.35 0.70]);
plot([0 20], [p.Cost_replacement p.Cost_replacement], '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.6);
yline(0, 'k-');
grid on; xlim([0 20]);
xlabel('Years'); ylabel('Cumulative value [Rs]');
legend('Cumulative bill savings', 'Cumulative battery degradation', ...
    'Net benefit', 'Battery replacement cost', 'Location', 'northwest');
title({'Cumulative economics over battery life', ...
    sprintf('Life %.1f yr at 80%% DoD - arbitrage margin is thin', ...
    p.N_cycles_rated * p.DoD_rated / (r.stage2.EFC * 365))});
print(f, fullfile(outdir, 'breakeven.png'), '-dpng', '-r150'); close(f);
end