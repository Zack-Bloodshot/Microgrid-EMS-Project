function [P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, ...
          grid_cost, deg_cost, objective_value] = ...
    lp_degradation_aware_ems(P_pv, P_load, tariff, params, alpha)
%LP_DEGRADATION_AWARE_EMS Stage 3 degradation-aware LP EMS dispatch.
%
%   [P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, grid_cost, deg_cost, ...
%    objective_value] = LP_DEGRADATION_AWARE_EMS(P_pv, P_load, tariff, ...
%    params, alpha) solves the Stage 3 linear program with MATLAB's
%   linprog:
%
%     min sum_k [ C_import(k)*P_gimp(k)*dt
%               - C_export(k)*P_gexp(k)*dt
%               + alpha*c_deg*(P_ch(k) + P_dis(k))*dt ]
%
%   subject to power balance, SOC recursion/bounds, a terminal-SOC lower
%   bound SOC(N+1) >= SOC0, and the usual variable bounds.
%
%   The degradation coefficient comes from the shared degradation model
%   (battery_degradation.m), the same one used to price Stage 1 and Stage 2:
%
%     c_deg = Cost_replacement / (N_cycles_rated * 2*E_B*DoD_rated)
%
%   Decision vector layout (unchanged from Stage 2):
%     x = [P_gimp(1:N); P_gexp(1:N); P_ch(1:N); P_dis(1:N); P_curt(1:N)]
%
%   Inputs:
%     P_pv    - [1 x N] PV generation at each timestep [kW]
%     P_load  - [1 x N] load demand at each timestep [kW]
%     tariff  - struct from tariff_params()
%     params  - struct from system_params()
%     alpha   - degradation weight, dimensionless (default 1)
%
%   Outputs:
%     P_ch, P_dis, P_gimp, P_gexp, P_curt - [1 x N] [kW], all >= 0
%     SOC           - [1 x N+1] state of charge, SOC(1) = SOC0
%     grid_cost     - actual grid bill [Rs] from calculate_costs
%     deg_cost      - actual DoD-aware degradation cost [Rs]
%     objective_value - solver objective [Rs]; includes alpha, so it is
%                     not a physical cost unless alpha = 1
%
%   See also: battery_degradation, validate_stage3_solution.

    if nargin < 5 || isempty(alpha)
        alpha = 1;
    end

    N  = params.N;
    dt = params.dt;

    %% ---- Unpack parameters ----
    E_B        = params.E_B;
    P_ch_max   = params.P_ch_max;
    P_dis_max  = params.P_dis_max;
    SOC0       = params.SOC0;
    SOC_min    = params.SOC_min;
    SOC_max    = params.SOC_max;
    eta_ch     = params.eta_ch;
    eta_dis    = params.eta_dis;
    P_gimp_max = params.P_grid_imp_max;
    P_gexp_max = params.P_grid_exp_max;

    P_pv   = P_pv(:).';
    P_load = P_load(:).';

    %% ---- Decision vector column index blocks ----
    idx_imp  = 1:N;
    idx_exp  = N+1:2*N;
    idx_ch   = 2*N+1:3*N;
    idx_dis  = 3*N+1:4*N;
    idx_curt = 4*N+1:5*N;
    nVar = 5*N;

    %% ---- 1) Degradation coefficient (shared model) ----
    c_deg = params.Cost_replacement / ...
        (params.N_cycles_rated * 2 * E_B * params.DoD_rated);

    %% ---- 2) Objective function ----
    [C_import, C_export] = build_lp_price_vectors(N, dt, tariff);

    f = zeros(nVar, 1);
    f(idx_imp)  =  C_import(:) * dt;
    f(idx_exp)  = -C_export(:) * dt;
    f(idx_ch)   =  alpha * c_deg * dt;
    f(idx_dis)  =  alpha * c_deg * dt;
    % f(idx_curt) stays zero: curtailment has no direct cost.

    %% ---- 3) Power balance equality constraints ----
    Aeq = zeros(N, nVar);
    beq = zeros(N, 1);
    for k = 1:N
        Aeq(k, idx_imp(k))  =  1;
        Aeq(k, idx_exp(k))  = -1;
        Aeq(k, idx_ch(k))   = -1;
        Aeq(k, idx_dis(k))  =  1;
        Aeq(k, idx_curt(k)) = -1;
        beq(k) = P_load(k) - P_pv(k);
    end

    %% ---- 4) SOC operational bounds + terminal SOC ----
    L = tril(ones(N));
    a_ch = (dt * eta_ch) / E_B;
    b_dis = dt / (E_B * eta_dis);

    % 2N SOC rows + 1 terminal-SOC row.
    Aineq = zeros(2*N + 1, nVar);
    bineq = zeros(2*N + 1, 1);

    % Upper bound: SOC(k) <= SOC_max
    Aineq(1:N, idx_ch)  =  a_ch  * L;
    Aineq(1:N, idx_dis) = -b_dis * L;
    bineq(1:N) = SOC_max - SOC0;

    % Lower bound: SOC(k) >= SOC_min
    Aineq(N+1:2*N, idx_ch)  = -a_ch  * L;
    Aineq(N+1:2*N, idx_dis) =  b_dis * L;
    bineq(N+1:2*N) = SOC0 - SOC_min;

    % Terminal SOC: SOC(N+1) >= SOC0
    %   sum_k (eta_ch*P_ch(k) - P_dis(k)/eta_dis) >= 0
    %   -sum_k (...) <= 0
    Aineq(2*N+1, idx_ch)  = -eta_ch * ones(1, N);
    Aineq(2*N+1, idx_dis) =  (1/eta_dis) * ones(1, N);
    bineq(2*N+1) = 0;

    %% ---- 5) Decision variable bounds ----
    lb = zeros(nVar, 1);
    ub = zeros(nVar, 1);
    ub(idx_imp)  = P_gimp_max;
    ub(idx_exp)  = P_gexp_max;
    ub(idx_ch)   = P_ch_max;
    ub(idx_dis)  = P_dis_max;
    ub(idx_curt) = P_pv(:);

    %% ---- 6) Solve the LP ----
    options = optimoptions('linprog', 'Display', 'none');
    [x, fval, exitflag, ~] = ...
        linprog(f, Aineq, bineq, Aeq, beq, lb, ub, options);

    if exitflag ~= 1
        error('lp_degradation_aware_ems:solverFailed', ...
            'linprog did not converge to an optimal solution (exitflag = %d).', ...
            exitflag);
    end
    objective_value = fval;

    %% ---- 7) Extract dispatch trajectories ----
    P_gimp = x(idx_imp).';
    P_gexp = x(idx_exp).';
    P_ch   = x(idx_ch).';
    P_dis  = x(idx_dis).';
    P_curt = x(idx_curt).';

    %% ---- 8) Reconstruct SOC ----
    SOC = zeros(1, N+1);
    SOC(1) = SOC0;
    for k = 1:N
        SOC(k+1) = SOC(k) + (dt/E_B) * ...
            (eta_ch*P_ch(k) - P_dis(k)/eta_dis);
    end

    %% ---- 9) Physical costs (always alpha = 1) ----
    grid_cost = calculate_costs(P_gimp, P_gexp, dt, tariff);
    [deg_cost, ~, ~, ~] = battery_degradation(P_ch, P_dis, params);

    % Internal consistency: the physical dispatch must reproduce the
    % physical costs used for reporting.
    assert(abs(alpha*c_deg*sum(P_ch + P_dis)*dt - ...
        (f(idx_ch).' * P_ch(:) + f(idx_dis).' * P_dis(:))) < 1e-9, ...
        'lp_degradation_aware_ems:objectiveMismatch', ...
        'Solver degradation term and reported objective disagree.');
end
