function [C_import, C_export] = build_lp_price_vectors(N, dt, tariff)
%BUILD_LP_PRICE_VECTORS Per-timestep linear price vectors for the Phase 2 LP.
%
%   [C_import, C_export] = BUILD_LP_PRICE_VECTORS(N, dt, tariff) returns
%   the [1 x N] Time-of-Day (ToD) import price vector C_import(k) and
%   export credit vector C_export(k) required by the LP objective
%   (phase_2_implementation.md, Section 2):
%
%       min sum_k [ C_import(k)*P_grid,imp(k)*dt - C_export(k)*P_grid,exp(k)*dt ]
%
%   Design note:
%   The APDCL tariff in tariff_params.m bills energy on cumulative
%   MONTHLY slabs (see calculate_costs.m), which makes the true Rs/kWh
%   rate path-dependent on prior consumption and therefore non-linear.
%   A single-shot LP requires a fixed, linear per-timestep price
%   coefficient, so here the import price is approximated as the
%   lowest (first) monthly slab's effective rate scaled by the
%   published ToD multiplier for that timestep. This preserves the
%   day/night price signal that drives battery charge/discharge
%   arbitrage inside the LP, while the ACTUAL monetary grid_cost
%   reported by lp_naive_ems.m is computed separately and accurately
%   using the full slab-based calculate_costs.m model on the LP's
%   resulting P_gimp/P_gexp profiles.
%
%   Export credit has no ToD structure in tariff_params.m, so C_export
%   is held flat at tariff.export_compensation_rate.
%
%   Inputs:
%     N      - number of timesteps in the horizon
%     dt     - [h] timestep duration (unused directly here, kept for
%              interface symmetry with calculate_costs.m's ToD builder)
%     tariff - struct returned by tariff_params()
%
%   Outputs:
%     C_import - [1 x N] linear import price [Rs/kWh] at each timestep
%     C_export - [1 x N] export credit [Rs/kWh] at each timestep

    tod_multiplier = get_tod_multiplier(N, dt, tariff.tod);

    base_import_rate = tariff.slab_effective_rates(1); % lowest monthly slab
    C_import = base_import_rate * tod_multiplier;

    if tariff.net_metering
        % Under net metering, exported energy offsets imports at the same
        % time-of-use value instead of being treated as free energy.
        C_export = C_import;
    else
        C_export = tariff.export_compensation_rate * ones(1, N);
    end
end
