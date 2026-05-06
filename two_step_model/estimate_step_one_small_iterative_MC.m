function results = estimate_step_one_small_iterative_MC(data, config)

    T = data.T;

    N = data.N;

    % -------------------------------------------------
    % Fixed Monte Carlo draws
    % -------------------------------------------------

    M = 50;
    mc_draws = randn(M, 1);   % fixed common random numbers

    % -------------------------------------------------
    % Initial values
    % -------------------------------------------------

    a_mu = 0.1 * randn;
    b_mu = 0.02 * randn;

    a_log_sigma = -0.3 + 0.1 * randn;
    b_log_sigma = 0.01 * randn;

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

    trend_params = [a_mu; b_mu; a_log_sigma; b_log_sigma];

    nll_old = total_nll_trend_MC(trend_params, ...
        log_lambda_F, log_lambda_V, raw_phi, ...
        data, mc_draws);

    fprintf('\nInitial MC NLL = %.8f\n', nll_old);

    for iter = 1:config.max_outer_iter

        % =================================================
        % Block 1: optimize common trend parameters
        % =================================================

        obj_trend = @(theta_trend) total_nll_trend_MC(theta_trend, ...
            log_lambda_F, log_lambda_V, raw_phi, ...
            data, mc_draws);

        [trend_params_hat, ~] = fminunc(obj_trend, trend_params, small_opts);

        trend_params = trend_params_hat(:);

        % =================================================
        % Block 2: optimize individual parameters
        % =================================================

        [mu, log_sigma] = make_mu_logsigma_from_trend(trend_params, T);

        for ii = 1:N

            theta_i0 = [log_lambda_F(ii); log_lambda_V(ii); raw_phi(ii)];

            obj_i = @(theta_i) individual_nll_MC(theta_i, ii, ...
                mu, log_sigma, ...
                data, mc_draws);

            [theta_i_hat, ~] = fminunc(obj_i, theta_i0, small_opts);

            log_lambda_F(ii) = theta_i_hat(1);

            log_lambda_V(ii) = theta_i_hat(2);

            raw_phi(ii) = theta_i_hat(3);

        end

        % =================================================
        % Check convergence
        % =================================================

        nll_new = total_nll_trend_MC(trend_params, ...
            log_lambda_F, log_lambda_V, raw_phi, ...
            data, mc_draws);

        nll_history(iter) = nll_new;

        rel_change = abs(nll_old - nll_new) / max(1, abs(nll_old));

        fprintf('Iter %3d: MC NLL = %.8f, rel change = %.3e\n', ...
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
    results.a_log_sigma = trend_params(3);
    results.b_log_sigma = trend_params(4);

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
    results.mc_draws = M;

end



function [mu, log_sigma] = make_mu_logsigma_from_trend(trend_params, T)

    a_mu = trend_params(1);

    b_mu = trend_params(2);

    a_log_sigma = trend_params(3);

    b_log_sigma = trend_params(4);

    t_grid = (1:T)';

    mu = a_mu + b_mu * t_grid;

    log_sigma = a_log_sigma + b_log_sigma * t_grid;

end


function nll = total_nll_trend_MC(trend_params, ...
    log_lambda_F, log_lambda_V, raw_phi, ...
    data, mc_draws)

    T = data.T;

    [mu, log_sigma] = make_mu_logsigma_from_trend(trend_params, T);

    nll = 0;

    for tt = 1:T

        theta_t = [mu(tt); log_sigma(tt)];

        nll = nll + period_nll_MC(theta_t, tt, ...
            log_lambda_F, log_lambda_V, raw_phi, ...
            data, mc_draws);

    end

end



function nll = period_nll_MC(theta_t, tt, ...
    log_lambda_F, log_lambda_V, raw_phi, ...
    data, mc_draws)

    mu_t = theta_t(1);
    sigma_t = exp(theta_t(2));

    lambda_F = exp(log_lambda_F);
    lambda_V = exp(log_lambda_V);
    phi = 1 ./ (1 + exp(-raw_phi));

    idx = data.match == tt;

    y_t = data.y(idx);
    id_idx_t = data.id_index(idx);

    lambda_it = lambda_F(id_idx_t) + phi(id_idx_t).^tt .* lambda_V(id_idx_t);

    % MC draws for alpha
    log_alpha_draws = mu_t + sigma_t * mc_draws(:);
    alpha_draws = exp(log_alpha_draws);

    % M x 1
    Delta = (50 - data.Gamma) - alpha_draws * (data.Gamma - 25);

    % M x n_obs_t
    z = Delta ./ lambda_it';

    p_defect_draws = stable_logit(z);

    % Average over MC draws
    p_defect = mean(p_defect_draws, 1)';

    p_y = (1 - p_defect) .* (y_t == 1) + ...
           p_defect  .* (y_t == 0);

    p_y = min(max(p_y, 1e-12), 1 - 1e-12);

    nll = -sum(log(p_y));

end


function nll = individual_nll_MC(theta_i, ii, ...
    mu, log_sigma, ...
    data, mc_draws)

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

        log_alpha_draws = mu_t + sigma_t * mc_draws(:);
        alpha_draws = exp(log_alpha_draws);

        Delta = (50 - data.Gamma) - alpha_draws * (data.Gamma - 25);

        z = Delta ./ lambda_it;

        p_defect_draws = stable_logit(z);

        p_defect = mean(p_defect_draws);

        if y_i(k) == 1
            p_y = 1 - p_defect;
        else
            p_y = p_defect;
        end

        p_y = min(max(p_y, 1e-12), 1 - 1e-12);

        nll = nll - log(p_y);

    end

end


