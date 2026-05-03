function results = estimate_step_one(data, config)
    
    % Get dimensions
    T = data.T;
    N = data.N;

    % Quadrature nodes
    [nodes, weights] = gauss_hermite_rule(config.quad_nodes);


    % Objective function
    objective = @(theta) negloglik(theta, data, nodes, weights);

    
    % -------------------------------------
    % Define Initial values
    % -------------------------------------

    theta0 = zeros(2*T + 3*N, 1);

    % mu_t
    theta0(1:T) = 0;

    % log sigma_t
    theta0(T+1 : 2*T) = log(1);

    % log lambda_F_i
    pos = 2*T;
    theta0(pos+1 : pos+N) = log(1);
    pos = pos + N;

    % log lambda_V_i
    theta0(pos+1 : pos+N) = log(1);
    pos = pos + N;

    % raw phi_i
    % raw_phi = 0 implies phi = 0.5
    theta0(pos+1 : pos+N) = 0;



    % -------------------------
    % Optimization
    % -------------------------

    options = optimoptions('fminunc', ...
        'Algorithm', 'quasi-newton', ...
        'Display', 'iter', ...
        'MaxFunctionEvaluations', 1e6, ...
        'MaxIterations', 5e3, ...
        'OptimalityTolerance', 1e-8, ...
        'StepTolerance', 1e-10);

    % [theta_hat, negLogLik, exitflag, output, grad, hessian] = ...
    %     fminunc(objective, theta0, options);
    [theta_hat, negLogLik, exitflag, output, grad] = ...
        fminunc(objective, theta0, options);

    theta_hat = theta_hat(:);


    % -------------------------
    % Store basic output
    % -------------------------

    results = struct();
    results.theta0 = theta0;
    results.theta_hat = theta_hat;
    results.negLogLik = negLogLik;
    results.exitflag = exitflag;
    results.output = output;
    results.gradient = grad;
    % results.hessian = hessian;


    % -------------------------
    % Unpack estimates
    % -------------------------

    [mu, sigma, lambda_F, lambda_V, phi] = unpack_theta(theta_hat, T, N);

    results.mu = mu;
    results.sigma = sigma;
    results.lambda_F = lambda_F;
    results.lambda_V = lambda_V;
    results.phi = phi;


    % -------------------------
    % Standard errors
    % -------------------------

    % if ~isempty(hessian) && all(isfinite(hessian(:))) && rcond(hessian) > 1e-12
    % 
    %     vcov = inv(hessian);
    %     se_theta = sqrt(max(diag(vcov), 0));
    % 
    %     results.vcov = vcov;
    %     results.se_theta = se_theta;
    % 
    % 
    %     % Raw and transformed parameter SEs
    %     results.se_mu = se_theta(1:T);
    % 
    %     results.se_log_sigma = se_theta(T+1 : 2*T);
    %     results.se_sigma = sigma .* results.se_log_sigma;
    % 
    %     pos = 2*T;
    %     results.se_log_lambda_F = se_theta(pos+1 : pos+N);
    %     results.se_lambda_F = lambda_F .* results.se_log_lambda_F;
    % 
    %     pos = pos + N;
    %     results.se_log_lambda_V = se_theta(pos+1 : pos+N);
    %     results.se_lambda_V = lambda_V .* results.se_log_lambda_V;
    % 
    %     pos = pos + N;
    %     results.se_raw_phi = se_theta(pos+1 : pos+N);
    %     results.se_phi = phi .* (1 - phi) .* results.se_raw_phi;
    % 
    % else
    %     results.vcov = [];
    %     results.se_theta = NaN(K, 1);
    %     results.se_mu = NaN(T, 1);
    %     results.se_log_sigma = NaN(T, 1);
    %     results.se_sigma_delta = NaN(T, 1);
    %     results.se_log_lambda_F = NaN(N, 1);
    %     results.se_lambda_F_delta = NaN(N, 1);
    %     results.se_log_lambda_V = NaN(N, 1);
    %     results.se_lambda_V_delta = NaN(N, 1);
    %     results.se_raw_phi = NaN(N, 1);
    %     results.se_phi_delta = NaN(N, 1);
    % end

end



function nll = negloglik(theta, data, nodes, weights)
    
    T = data.T;
    N = data.N;

    % ---------- unpack parameters ----------

    mu = theta(1:T);

    log_sigma = theta(T+1 : 2*T);
    sigma = exp(log_sigma);

    pos = 2*T;

    log_lambda_F = theta(pos + 1 : pos + N);
    lambda_F = exp(log_lambda_F);

    pos = pos + N;

    log_lambda_V = theta(pos + 1 : pos + N);
    lambda_V = exp(log_lambda_V);

    pos = pos + N;

    raw_phi = theta(pos + 1 : pos + N);
    phi = 1 ./ (1 + exp(-raw_phi));   % force phi in (0,1)


    % ---------- loop over supergames ----------

    prob = zeros(length(data.y), 1);
    
    for tt = 1:T

        idx = (data.match == tt);

        y_t = data.y(idx);
        mu_t = mu(tt);
        sigma_t = sigma(tt);
        lambda_it = lambda_F + phi.^tt .* lambda_V;

        % Define alpha node for time t, for integration
        log_alpha_nodes = mu_t + sqrt(2) * sigma_t * nodes;
        alpha_nodes = exp(log_alpha_nodes);


        % dimensions:
        % alpha_nodes: Q x 1, where Q is the no. of quad nodes
        % lambda_it:  N x 1
        % We want Q x N matrix

        Delta = (50 - data.Gamma) - alpha_nodes * (data.Gamma - 25);
        z = Delta ./ lambda_it';   % Q x N
    
        p_defect_nodes = stable_logit(z);

        % integrate over alpha
        p_defect = (weights' * p_defect_nodes)' / sqrt(pi);

        p_y = (1 - p_defect) .* (y_t == 1) + ...
              p_defect .* (y_t == 0);

        prob(idx) = p_y;

    end

    prob = min(max(prob, 1e-12), 1 - 1e-12);
    nll = -sum(log(prob));

end


function [mu, sigma, lambda_F, lambda_V, phi] = unpack_theta(theta, T, N)

    theta = theta(:);
    
    mu = theta(1:T);

    log_sigma = theta(T+1 : 2*T);
    sigma = exp(log_sigma);

    pos = 2*T;
    log_lambda_F = theta(pos+1 : pos+N);
    lambda_F = exp(log_lambda_F);

    pos = pos + N;
    log_lambda_V = theta(pos+1 : pos+N);
    lambda_V = exp(log_lambda_V);

    pos = pos + N;
    raw_phi = theta(pos+1 : pos+N);
    phi = 1 ./ (1 + exp(-raw_phi));

end


