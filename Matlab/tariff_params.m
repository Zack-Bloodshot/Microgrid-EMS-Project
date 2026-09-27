function tariff = tariff_params()
%TARIFF_PARAMS APDCL FY 2026-27 LT-III Domestic-B tariff data.
%
%   Returns the tariff values published in the supplied APDCL notice,
%   effective from 01-Apr-2026. Energy charges are effective tariffs after
%   the stated government subsidies. Billing uses 1:1 net metering.

    tariff = struct();
    tariff.category = 'LT-III Domestic-B (5 kW to 30 kW)';
    tariff.currency = 'Rs';

    %% --- Monthly fixed and energy charges from the notice ---
    tariff.fixed_charge = 70.00;       % [Rs/month]
    tariff.fixed_charge_basis = 'per connection per month';
    tariff.slab_limits_kWh = [300, 500]; % [kWh/month], third slab is balance
    tariff.slab_effective_rates = [6.75, 6.95, 7.74]; % [Rs/kWh]
    tariff.slab_full_cost_rates = [7.74, 7.74, 7.74]; % [Rs/kWh]

    %% --- Revised ToD multipliers from the notice ---
    tariff.tod.normal_hours = [22, 9];  % 22:00-09:00, crosses midnight
    tariff.tod.solar_hours  = [9, 17];  % 09:00-17:00
    tariff.tod.peak_hours   = [17, 22]; % 17:00-22:00
    tariff.tod.normal_multiplier = 1.00;
    tariff.tod.solar_multiplier  = 0.80;
    tariff.tod.peak_multiplier   = 1.20;

end