function [P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, grid_cost, deg_cost] = ...
    lp_naive_ems(P_pv, P_load, tariff, params)
%LP_NAIVE_EMS Phase 2 LP-based Energy Management System dispatch.
%
%   [P_ch, P_dis, P_gimp, P_gexp, SOC, P_curt, grid_cost, deg_cost] = ...
%       LP_NAIVE_EMS(P_pv, P_load, tariff, params)
%   solves the Phase 2 naive (degradation-unaware) linear program
%   exactly as specified in phase_2_implementation.md, using MATLAB's
%   linprog:
%
%     - Objective (Section 2): minimize total grid energy cost under
%       ToD import/export prices, with NO degradation penalty in the
%       objective (degradation cost is a post-hoc, Section "Post-
%       Simulation Battery Degradation Quantification" calculation only).
%     - Power balance equality constraints (Section 3).
%     - SOC recursion / operational bounds via a cumulative-sum
%       inequality formulation (Section 4).
%     - Decision variable bounds (Section 5).
%
%   Decision vector layout:
%   Section 1 of the documentation defines the stacked decision vector
%   as x = [P_grid,imp(1:N); P_grid,exp(1:N); P_ch(1:N); P_dis(1:N)].
%   The Section 3 power-balance equation itself, however, explicitly
%   includes a P_curt(k) term:
%
%       P_grid,imp(k) - P_grid,exp(k) + P_dis(k) - P_ch(k) - P_curt(k)
%           = P_load(k) - P_pv(k)
%
%   which the abbreviated "matrix mapping" note omits. Treating that
%   equation with only 4 variables would make P_curt structurally
%   identically zero (it could never be nonzero), silently defeating
%   the purpose of tracking curtailment. This implementation therefore
%   extends the decision vector to x in R^(5N) by appending P_curt(1:N)
%   as a bounded decision variable (0 <= P_curt(k) <= P_pv(k)), which
%   makes the literal Section 3 equation solvable as written while
%   leaving every other equation, bound, and the objective function
%   completely unchanged (P_curt carries zero cost coefficient, so it
%   is only ever used by the solver when physically necessary).
%
%   Inputs:
%     P_pv    - [1 x N] PV generation at each timestep [kW]
%     P_load  - [1 x N] load demand at each timestep [kW]
%     tariff  - struct from tariff_params() (ToD multipliers, export rate)
%     params  - struct from system_params()
%
%   Outputs:
%     P_ch      - [1 x N] battery charge power [kW]            (>= 0)
%     P_dis     - [1 x N] battery discharge power [kW]         (>= 0)
%     P_gimp    - [1 x N] grid import power [kW]                (>= 0)
%     P_gexp    - [1 x N] grid export power [kW]                (>= 0)
%     SOC       - [1 x N+1] state of charge trajectory, SOC(1) = SOC0
%     P_curt    - [1 x N] curtailed PV power [kW]                (>= 0)
%     grid_cost - scalar, direct monetary cost paid to the utility under
%                 the full ToD tariff (Rs), computed via calculate_costs.m
%                 on the resulting P_gimp/P_gexp profiles
%     deg_cost  - scalar, post-simulation estimated battery degradation
%                 cost (Rs), unpenalized in the solver (Section
%                 "Post-Simulation Battery Degradation Quantification")

    N  = params.N;
    dt = params.dt;

    % Unpack battery/grid parameters
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

    P_pv   = P_pv(:).';    % ensure row vectors
    P_load = P_load(:).';

    %% ---- Decision vector column index blocks ----
    % x = [P_gimp(1:N); P_gexp(1:N); P_ch(1:N); P_dis(1:N); P_curt(1:N)]
    idx_imp  = 1:N;
    idx_exp  = N+1:2*N;
    idx_ch   = 2*N+1:3*N;
    idx_dis  = 3*N+1:4*N;
    idx_curt = 4*N+1:5*N;
    nVar = 5*N;

    %% ---- 1) Objective function (Section 2) ----
    [C_import, C_export] = build_lp_price_vectors(N, dt, tariff);

    f = zeros(nVar, 1);
    f(idx_imp) =  C_import(:) * dt;
    f(idx_exp) = -C_export(:) * dt;
    % f(idx_ch), f(idx_dis), f(idx_curt) remain 0: no degradation
    % penalty and no curtailment penalty in the naive objective.

    %% ---- 2) Power balance equality constraints (Section 3) ----
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

    %% ---- 3) SOC operational bound inequality constraints (Section 4) ----
    L = tril(ones(N));         % lower-triangular cumulative-sum operator
    alpha = (dt * eta_ch) / E_B;
    beta  = dt / (E_B * eta_dis);

    Aineq = zeros(2*N, nVar);
    bineq = zeros(2*N, 1);

    % Upper bound: SOC(k) <= SOC_max
    Aineq(1:N, idx_ch)  =  alpha * L;
    Aineq(1:N, idx_dis) = -beta  * L;
    bineq(1:N) = SOC_max - SOC0;

    % Lower bound: SOC(k) >= SOC_min  ->  -SOC(k) <= -SOC_min
    Aineq(N+1:2*N, idx_ch)  = -alpha * L;
    Aineq(N+1:2*N, idx_dis) =  beta  * L;
    bineq(N+1:2*N) = SOC0 - SOC_min;

    %% ---- 4) Decision variable bounds (Section 5, + curtailment cap) ----
    lb = zeros(nVar, 1);
    ub = zeros(nVar, 1);
    ub(idx_imp)  = P_gimp_max;
    ub(idx_exp)  = P_gexp_max;
    ub(idx_ch)   = P_ch_max;
    ub(idx_dis)  = P_dis_max;
    ub(idx_curt) = P_pv(:);    % cannot curtail more than generated PV

    %% ---- 5) Solve the LP ----
    options = optimoptions('linprog', 'Display', 'none');
    [x, ~, exitflag, ~] = linprog(f, Aineq, bineq, Aeq, beq, lb, ub, options);

    if exitflag ~= 1
        error('lp_naive_ems:solverFailed', ...
            'linprog did not converge to an optimal solution (exitflag = %d).', exitflag);
    end

    %% ---- 6) Extract dispatch trajectories ----
    P_gimp = x(idx_imp).';
    P_gexp = x(idx_exp).';
    P_ch   = x(idx_ch).';
    P_dis  = x(idx_dis).';
    P_curt = x(idx_curt).';

    %% ---- 7) Reconstruct SOC trajectory (Section 4, SOC recursion) ----
    SOC = zeros(1, N+1);
    SOC(1) = SOC0;
    for k = 1:N
        SOC(k+1) = SOC(k) + (dt/E_B) * (eta_ch*P_ch(k) - P_dis(k)/eta_dis);
    end

    %% ---- 8) Grid monetary cost (accurate slab-based tariff) ----
    grid_cost = calculate_costs(P_gimp, P_gexp, dt);

    %% ---- 9) Post-hoc battery degradation cost ----
    deg_cost = battery_degradation(P_ch, P_dis, params);

end
