function results = estimate_step_one_fix_sigma(data, config)

    T = data.T;
    N = data.N;

    [nodes, weights] = gauss_hermite_rule(config.quad_nodes);

    % -------------------------------------------------
    % Trend parameters
    %
    % mu_t        = a_mu + b_mu * t
    % log_sigma_t = a_sig + b_sig * t
    % sigma_t     = exp(log_sigma_t)
    % -------------------------------------------------

    % a_mu = 0;
    % b_mu = 0;
    % 
    % a_log_sigma = 0;
    % b_log_sigma = 0;
    % 
    % log_lambda_F = zeros(N, 1);
    % log_lambda_V = zeros(N, 1);
    % raw_phi = zeros(N, 1);

    a_mu = 0.1 * randn;
    b_mu = 0.02 * randn;
    % a_log_sigma = -0.3 + 0.1 * randn;
    % b_log_sigma = 0.01 * randn;

    log_lambda_F = 0.3 * randn(N, 1);
    log_lambda_V = -0.5 + 0.3 * randn(N, 1);
    raw_phi = 0.2 * randn(N, 1);
    
    small_opts = optimoptions('fminunc', ...
        'Algorithm', 'quasi-newton', ...
        'Display', 'off', ...
        'MaxFunctionEvaluations', 5000, ...
        'MaxIterations', 1000, ...
        'OptimalityTolerance', 1e-8, ...
        'StepTolerance', 1e-10);

    nll_history = NaN(config.max_outer_iter, 1);

    trend_params = [a_mu; b_mu];

    nll_old = total_nll_trend(trend_params, ...
        log_lambda_F, log_lambda_V, raw_phi, ...
        data, nodes, weights);

    fprintf('\nInitial NLL = %.8f\n', nll_old);

    for iter = 1:config.max_outer_iter

        % =================================================
        % Block 1: optimize common trend parameters
        % =================================================

        obj_trend = @(theta_trend) total_nll_trend(theta_trend, ...
            log_lambda_F, log_lambda_V, raw_phi, ...
            data, nodes, weights);

        [trend_params_hat, ~] = fminunc(obj_trend, trend_params, small_opts);

        trend_params = trend_params_hat(:);

        
        % =================================================
        % Block 2: optimize individual parameters
        % =================================================

        [mu, log_sigma] = make_mu_logsigma_from_trend(trend_params, T);

        for ii = 1:N

            theta_i0 = [log_lambda_F(ii); log_lambda_V(ii); raw_phi(ii)];

            obj_i = @(theta_i) individual_nll(theta_i, ii, ...
                mu, log_sigma, ...
                data, nodes, weights);

            [theta_i_hat, ~] = fminunc(obj_i, theta_i0, small_opts);

            log_lambda_F(ii) = theta_i_hat(1);
            log_lambda_V(ii) = theta_i_hat(2);
            raw_phi(ii) = theta_i_hat(3);

        end

        % =================================================
        % Check convergence
        % =================================================

        nll_new = total_nll_trend(trend_params, ...
            log_lambda_F, log_lambda_V, raw_phi, ...
            data, nodes, weights);

        nll_history(iter) = nll_new;

        rel_change = abs(nll_old - nll_new) / max(1, abs(nll_old));

        fprintf('Iter %3d: NLL = %.8f, rel change = %.3e\n', ...
            iter, nll_new, rel_change);

        if rel_change < config.outer_tol
            fprintf('Converged at outer iteration %d.\n', iter);
            break;
        end

        nll_old = nll_new;

    end

    nll_history = nll_history(~isnan(nll_history));

    [mu, log_sigma] = make_mu_logsigma_from_trend(trend_params, T);

    results = struct();

    results.trend_params = trend_params;
    results.a_mu = trend_params(1);
    results.b_mu = trend_params(2);
    results.a_log_sigma = log(2);
    results.b_log_sigma = 0;

    results.mu = mu;
    results.log_sigma = log_sigma;
    results.sigma = exp(log_sigma);

    results.log_lambda_F = log_lambda_F;
    results.log_lambda_V = log_lambda_V;
    results.raw_phi = raw_phi;

    results.lambda_F = exp(log_lambda_F);
    results.lambda_V = exp(log_lambda_V);
    results.phi = 1 ./ (1 + exp(-raw_phi));

    results.negLogLik = nll_history(end);
    results.nll_history = nll_history;
    results.num_outer_iter = numel(nll_history);

end



function [mu, log_sigma] = make_mu_logsigma_from_trend(trend_params, T)

    a_mu = trend_params(1);
    b_mu = trend_params(2);

    t_grid = (1:T)';

    mu = a_mu + b_mu * t_grid;
    log_sigma = log(2) * ones(T, 1);

end



function nll = total_nll_trend(trend_params, ...
    log_lambda_F, log_lambda_V, raw_phi, ...
    data, nodes, weights)

    T = data.T;

    [mu, log_sigma] = make_mu_logsigma_from_trend(trend_params, T);

    nll = 0;

    for tt = 1:T

        theta_t = [mu(tt); log_sigma(tt)];

        nll = nll + period_nll(theta_t, tt, ...
            log_lambda_F, log_lambda_V, raw_phi, ...
            data, nodes, weights);

    end

end



function nll = period_nll(theta_t, tt, ...
    log_lambda_F, log_lambda_V, raw_phi, ...
    data, nodes, weights)

    mu_t = theta_t(1);
    sigma_t = exp(theta_t(2));

    lambda_F = exp(log_lambda_F);
    lambda_V = exp(log_lambda_V);
    phi = 1 ./ (1 + exp(-raw_phi));

    idx = data.match == tt;

    y_t = data.y(idx);

    id_idx_t = data.id_index(idx);

    lambda_it = lambda_F(id_idx_t) + phi(id_idx_t).^tt .* lambda_V(id_idx_t);

    log_alpha_nodes = mu_t + sqrt(2) * sigma_t * nodes(:);

    alpha_nodes = exp(log_alpha_nodes);

    Delta = (50 - data.Gamma) - alpha_nodes * (data.Gamma - 25);

    z = Delta ./ lambda_it';

    p_defect_nodes = stable_logit(z);

    p_defect = (weights(:)' * p_defect_nodes)' / sqrt(pi);

    p_y = (1 - p_defect) .* (y_t == 1) + ...
           p_defect  .* (y_t == 0);

    p_y = min(max(p_y, 1e-12), 1 - 1e-12);

    nll = -sum(log(p_y));

end




function nll = individual_nll(theta_i, ii, ...
    mu, log_sigma, ...
    data, nodes, weights)

    log_lambda_F_i = theta_i(1);
    log_lambda_V_i = theta_i(2);
    raw_phi_i = theta_i(3);

    lambda_F_i = exp(log_lambda_F_i);
    lambda_V_i = exp(log_lambda_V_i);
    phi_i = 1 ./ (1 + exp(-raw_phi_i));

    idx_i = data.id_index == ii;

    y_i = data.y(idx_i);

    match_i = data.match(idx_i);

    nll = 0;

    for k = 1:numel(y_i)

        tt = match_i(k);

        mu_t = mu(tt);

        sigma_t = exp(log_sigma(tt));

        lambda_it = lambda_F_i + phi_i.^tt .* lambda_V_i;

        log_alpha_nodes = mu_t + sqrt(2) * sigma_t * nodes(:);

        alpha_nodes = exp(log_alpha_nodes);

        Delta = (50 - data.Gamma) - alpha_nodes * (data.Gamma - 25);

        z = Delta ./ lambda_it;

        p_defect_nodes = stable_logit(z);

        p_defect = (weights(:)' * p_defect_nodes) / sqrt(pi);

        if y_i(k) == 1

            p_y = 1 - p_defect;

        else

            p_y = p_defect;

        end

        p_y = min(max(p_y, 1e-12), 1 - 1e-12);
        nll = nll - log(p_y);

    end

end

