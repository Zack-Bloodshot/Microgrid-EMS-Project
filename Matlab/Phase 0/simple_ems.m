function [P_gimp, P_gexp, P_curt] = simple_ems(P_pv, P_load, params)
%RULE_BASED_EMS Phase 0 no-storage rule-based dispatch.
%
%   PV serves the load first. A surplus is exported up to the grid export
%   limit and the remainder is curtailed. A deficit is supplied by grid
%   import up to the grid import limit.

    if numel(P_pv) ~= params.N || numel(P_load) ~= params.N
        error('rule_based_ems:dimensionMismatch', ...
            'PV and load profiles must each contain params.N samples.');
    end

    P_pv = reshape(P_pv, 1, []);
    P_load = reshape(P_load, 1, []);
    P_gimp = zeros(1, params.N);
    P_gexp = zeros(1, params.N);
    P_curt = zeros(1, params.N);

    for k = 1:params.N
        P_net = P_pv(k) - P_load(k);

        if P_net >= 0
            P_gexp(k) = min(P_net, params.P_grid_exp_max);
            P_curt(k) = P_net - P_gexp(k);
        else
            P_gimp(k) = min(-P_net, params.P_grid_imp_max);
        end
    end
end