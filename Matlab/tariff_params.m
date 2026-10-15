function tariff = tariff_params(overrides)
%TARIFF_PARAMS APDCL FY 2026-27 LT-III Domestic-B tariff data.
%
%   tariff = TARIFF_PARAMS() returns the tariff as published.
%   tariff = TARIFF_PARAMS(overrides) applies a struct of fields to
%   override before returning. Supported override keys:
%     export_rate, peak_multiplier, solar_multiplier, normal_multiplier,
%     net_metering. Intended for sensitivity analysis only; omitting the
%   argument reproduces the published tariff exactly.
%
%   Returns the tariff values published in the supplied APDCL notice,
%   effective from 01-Apr-2026. Energy charges are effective tariffs after
%   the stated government subsidies.
%
%   Source boundary: every value below marked "notice" is taken from the
%   APDCL FY2026-27 tariff notice. The export compensation rate is NOT
%   published in the notice and is a stated project assumption.

    tariff = struct();
    tariff.category = 'LT-III Domestic-B (5 kW to 30 kW)';
    tariff.currency = 'Rs';

    %% --- Monthly fixed and energy charges (notice) ---
    tariff.fixed_charge = 70.00;       % [Rs/month]
    tariff.fixed_charge_basis = 'per connection per month';
    tariff.slab_limits_kWh = [300, 500]; % [kWh/month], third slab is balance
    tariff.slab_effective_rates = [6.75, 6.95, 7.74]; % [Rs/kWh]

    %% --- ToD multipliers (notice) ---
    tariff.tod.solar_hours  = [9, 17];   % 09:00-17:00, 80% of normal rate
    tariff.tod.peak_hours   = [17, 22];  % 17:00-22:00, 120% of normal rate
    tariff.tod.normal_multiplier = 1.00;
    tariff.tod.solar_multiplier  = 0.80;
    tariff.tod.peak_multiplier   = 1.20;

    %% --- Export compensation ---
    % ASSUMPTION: the APDCL notice publishes no feed-in / export
    % compensation rate. Rs 4.00/kWh is a project assumption, not a
    % tariff value, and is used only for scenario comparison.
    tariff.export_compensation_rate = 4.00; % [Rs/kWh], assumed
    tariff.net_metering = false;

    %% --- Optional overrides (sensitivity analysis) ---
    if nargin > 0 && ~isempty(overrides)
        if isfield(overrides, 'export_rate')
            tariff.export_compensation_rate = overrides.export_rate;
        end
        if isfield(overrides, 'peak_multiplier')
            tariff.tod.peak_multiplier = overrides.peak_multiplier;
        end
        if isfield(overrides, 'solar_multiplier')
            tariff.tod.solar_multiplier = overrides.solar_multiplier;
        end
        if isfield(overrides, 'normal_multiplier')
            tariff.tod.normal_multiplier = overrides.normal_multiplier;
        end
        if isfield(overrides, 'net_metering')
            tariff.net_metering = overrides.net_metering;
        end
    end
end