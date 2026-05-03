function results = estimate_step_one_small(data, config)

    T = data.T;
    N = data.N;

    [nodes, weights] = gauss_hermite_rule(config.quad_nodes);

    objective = @(theta) negloglik_trend(theta, data, nodes, weights);

    % ------------------------------------------------
    % Parameters:
    %
    % theta = [
    %   a_mu
    %   b_mu
    %   a_log_sigma
    %   b_log_sigma
    %   log_lambda_F_i, i = 1,...,N
    %   log_lambda_V_i, i = 1,...,N
    %   raw_phi_i,      i = 1,...,N
    % ]
    % ------------------------------------------------

    K = 4 + 3*N;
    theta0 = zeros(K, 1);

    % mu_t = a_mu + b_mu * t
    theta0(1) = 0;   % a_mu
    theta0(2) = 0;   % b_mu

    % log_sigma_t = a_log_sigma + b_log_sigma * t
    theta0(3) = log(1);  % a_log_sigma
    theta0(4) = 0;       % b_log_sigma

    pos = 4;

    % log lambda_F
    theta0(pos+1 : pos+N) = log(1);
    pos = pos + N;

    % log lambda_V
    theta0(pos+1 : pos+N) = log(1);
    pos = pos + N;

    % raw phi
    theta0(pos+1 : pos+N) = 0;

    options = optimoptions('fminunc', ...
        'Algorithm', 'quasi-newton', ...
        'Display', 'iter', ...
        'MaxFunctionEvaluations', 1e6, ...
        'MaxIterations', 5e3, ...
        'OptimalityTolerance', 1e-8, ...
        'StepTolerance', 1e-10);

    [theta_hat, negLogLik, exitflag, output, grad] = ...
        fminunc(objective, theta0, options);

    theta_hat = theta_hat(:);

    results = struct();
    results.theta0 = theta0;
    results.theta_hat = theta_hat;
    results.negLogLik = negLogLik;
    results.exitflag = exitflag;
    results.output = output;
    results.gradient = grad;

    [mu, sigma, lambda_F, lambda_V, phi, trend_params] = ...
        unpack_theta_trend(theta_hat, T, N);

    results.mu = mu;
    results.sigma = sigma;
    results.lambda_F = lambda_F;
    results.lambda_V = lambda_V;
    results.phi = phi;

    results.trend_params = trend_params;

end



function nll = negloglik_trend(theta, data, nodes, weights)

    T = data.T;
    N = data.N;

    % ------------------------------------------------
    % Unpack trend parameters
    % ------------------------------------------------

    a_mu = theta(1);
    b_mu = theta(2);

    a_log_sigma = theta(3);
    b_log_sigma = theta(4);

    t_grid = (1:T)';

    mu = a_mu + b_mu * t_grid;

    log_sigma = a_log_sigma + b_log_sigma * t_grid;
    sigma = exp(log_sigma);

    % ------------------------------------------------
    % Unpack individual parameters
    % ------------------------------------------------

    pos = 4;

    log_lambda_F = theta(pos+1 : pos+N);
    lambda_F = exp(log_lambda_F);
    pos = pos + N;

    log_lambda_V = theta(pos+1 : pos+N);
    lambda_V = exp(log_lambda_V);
    pos = pos + N;

    raw_phi = theta(pos+1 : pos+N);
    phi = 1 ./ (1 + exp(-raw_phi));

    % ------------------------------------------------
    % Likelihood
    % ------------------------------------------------

    prob = zeros(length(data.y), 1);

    for tt = 1:T

        idx = (data.match == tt);

        y_t = data.y(idx);

        mu_t = mu(tt);
        sigma_t = sigma(tt);

        lambda_it = lambda_F + phi.^tt .* lambda_V;

        log_alpha_nodes = mu_t + sqrt(2) * sigma_t * nodes;
        alpha_nodes = exp(log_alpha_nodes);

        Delta = (50 - data.Gamma) - alpha_nodes * (data.Gamma - 25);

        z = Delta ./ lambda_it';

        p_defect_nodes = stable_logit(z);

        p_defect = (weights' * p_defect_nodes)' / sqrt(pi);

        p_y = (1 - p_defect) .* (y_t == 1) + ...
               p_defect  .* (y_t == 0);

        prob(idx) = p_y;

    end

    prob = min(max(prob, 1e-12), 1 - 1e-12);

    nll = -sum(log(prob));

end


function [mu, sigma, lambda_F, lambda_V, phi, trend_params] = ...
    unpack_theta_trend(theta, T, N)

    theta = theta(:);

    a_mu = theta(1);
    b_mu = theta(2);

    a_log_sigma = theta(3);
    b_log_sigma = theta(4);

    t_grid = (1:T)';

    mu = a_mu + b_mu * t_grid;

    log_sigma = a_log_sigma + b_log_sigma * t_grid;
    sigma = exp(log_sigma);

    pos = 4;

    log_lambda_F = theta(pos+1 : pos+N);
    lambda_F = exp(log_lambda_F);
    pos = pos + N;

    log_lambda_V = theta(pos+1 : pos+N);
    lambda_V = exp(log_lambda_V);
    pos = pos + N;

    raw_phi = theta(pos+1 : pos+N);
    phi = 1 ./ (1 + exp(-raw_phi));

    trend_params = struct();
    trend_params.a_mu = a_mu;
    trend_params.b_mu = b_mu;
    trend_params.a_log_sigma = a_log_sigma;
    trend_params.b_log_sigma = b_log_sigma;

end


