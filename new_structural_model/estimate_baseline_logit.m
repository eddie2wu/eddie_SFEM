function results = estimate_baseline_logit(data, config)
% Estimate the baseline hierarchical logit by maximum likelihood:
%
%   theta_i ~ N(mu_theta, sigma_theta^2)
%   epsilon_i,t ~ Logistic(0, s_t)
%   log(alpha_i,t) = theta_i + beta_t + epsilon_i,t
%
% With beta_last normalized to zero, the conditional cooperation
% probabilities are:
%
%   Pr(y_q2 = 1 | theta_i)   = Lambda((theta_i + beta_q2) / s_q2)
%   Pr(y_q3 = 1 | theta_i)   = Lambda((theta_i + beta_q3) / s_q3)
%   Pr(y_last = 1 | theta_i) = Lambda(theta_i / s_last)
%
% where Lambda is the standard logistic CDF.
%
% Integration over theta_i uses Gauss-Hermite quadrature.
% Identification is obtained by normalizing beta_last = 0.

    [nodes, weights] = gauss_hermite_rule(config.quad_nodes);

    objective = @(theta) baseline_neg_loglik(theta, data, nodes, weights);

    mean_q2 = mean(data.y_q2);
    mean_q3 = mean(data.y_q3);
    mean_last = mean(data.y_last);

    mu0 = logit_clip(mean_last);
    % theta0 = [mu0, log(0.5), logit_clip(mean_q2) - mu0, ...
    %     logit_clip(mean_q3) - mu0, 0, 0, 0];

    % theta0 = [
    %     randn * 1.0,        % mu_theta
    %     log(0.5) + 0.2*randn,   % log_sigma_theta
    %     randn * 0.5,        % beta_q2
    %     randn * 0.5,        % beta_q3
    %     log(1) + 0.2*randn, % log_s_q2
    %     log(1) + 0.2*randn, % log_s_q3
    %     log(1) + 0.2*randn  % log_s_last
    % ];
    
    theta0 = [
        randn,        % mu_theta
        randn,   % log_sigma_theta
        randn,        % beta_q2
        randn,        % beta_q3
        randn,  % log_s_q2
        randn,  % log_s_q3
        randn   % log_s_last
    ];

    results = struct();
    results.theta0 = theta0;
    results.quad_nodes = config.quad_nodes;

    options = optimoptions('fminunc', ...
    'Algorithm', 'quasi-newton', ...
    'Display', 'iter', ...
    'MaxFunctionEvaluations', 2e4, ...
    'MaxIterations', 2e3, ...
    'OptimalityTolerance', 1e-8, ...
    'StepTolerance', 1e-10);

    [theta_hat, negLogLik, exitflag, output, grad, hessian] = ...
        fminunc(objective, theta0, options);

    results.theta_hat = theta_hat(:);
    results.mu_theta = theta_hat(1);
    results.sigma_theta = exp(theta_hat(2));
    results.beta_q2 = theta_hat(3);
    results.beta_q3 = theta_hat(4);
    results.beta_last = 0;
    results.s_q2 = exp(theta_hat(5));
    results.s_q3 = exp(theta_hat(6));
    results.s_last = exp(theta_hat(7));
    results.negLogLik = negLogLik;
    results.exitflag = exitflag;
    results.output = output;
    results.gradient = grad;
    results.hessian = hessian;

    if ~isempty(hessian) && all(isfinite(hessian(:))) && rcond(hessian) > 1e-12
        vcov = inv(hessian);
        se_theta = sqrt(max(diag(vcov), 0));

        results.vcov = vcov;
        results.se_theta = se_theta;
        results.se_mu_theta = se_theta(1);
        results.se_log_sigma_theta = se_theta(2);
        results.se_sigma_theta_delta = results.sigma_theta * se_theta(2);
        results.se_beta_q2 = se_theta(3);
        results.se_beta_q3 = se_theta(4);
        results.se_beta_last = 0;
        results.se_log_s_q2 = se_theta(5);
        results.se_log_s_q3 = se_theta(6);
        results.se_log_s_last = se_theta(7);
        results.se_s_q2_delta = results.s_q2 * se_theta(5);
        results.se_s_q3_delta = results.s_q3 * se_theta(6);
        results.se_s_last_delta = results.s_last * se_theta(7);
    else
        results.vcov = [];
        results.se_theta = [];
        results.se_mu_theta = NaN;
        results.se_log_sigma_theta = NaN;
        results.se_sigma_theta_delta = NaN;
        results.se_beta_q2 = NaN;
        results.se_beta_q3 = NaN;
        results.se_beta_last = 0;
        results.se_log_s_q2 = NaN;
        results.se_log_s_q3 = NaN;
        results.se_log_s_last = NaN;
        results.se_s_q2_delta = NaN;
        results.se_s_q3_delta = NaN;
        results.se_s_last_delta = NaN;
    end
end



% Negative loglikelihood function
function nll = baseline_neg_loglik(theta, data, nodes, weights)
    mu_theta = theta(1);
    sigma_theta = exp(theta(2));
    beta_q2 = theta(3);
    beta_q3 = theta(4);
    s_q2 = exp(theta(5));
    s_q3 = exp(theta(6));
    s_last = exp(theta(7));

    theta_draws = mu_theta + sqrt(2) * sigma_theta * nodes(:)';
    like = zeros(data.N, 1);

    for i = 1:data.N
        threshold_i = data.threshold(i);

        p_q2 = logistic_stable((theta_draws + beta_q2 - threshold_i) ./ s_q2);
        p_q3 = logistic_stable((theta_draws + beta_q3 - threshold_i) ./ s_q3);
        p_last = logistic_stable((theta_draws - threshold_i) ./ s_last);
        
        % Ensure bounded in 0, 1
        p_q2 = min(max(p_q2, realmin), 1 - realmin);
        p_q3 = min(max(p_q3, realmin), 1 - realmin);
        p_last = min(max(p_last, realmin), 1 - realmin);

        term_q2 = p_q2 .^ data.y_q2(i) .* (1 - p_q2) .^ (1 - data.y_q2(i));
        term_q3 = p_q3 .^ data.y_q3(i) .* (1 - p_q3) .^ (1 - data.y_q3(i));
        term_last = p_last .^ data.y_last(i) .* (1 - p_last) .^ (1 - data.y_last(i));

        integrand = weights(:)' .* term_q2 .* term_q3 .* term_last;
        like(i) = sum(integrand) / sqrt(pi);
    end

    like = max(like, realmin);
    nll = -sum(log(like));
end

function p = logistic_stable(x)
    p = zeros(size(x));

    nonneg = (x >= 0);
    z = exp(-x(nonneg));
    p(nonneg) = 1 ./ (1 + z);

    z = exp(x(~nonneg));
    p(~nonneg) = z ./ (1 + z);
end



% Clip logit with p away from 0 and 1
function z = logit_clip(p)
    p = min(max(p, 1e-8), 1 - 1e-8);
    z = log(p ./ (1 - p));
end
