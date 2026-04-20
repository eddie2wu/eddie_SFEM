function results = estimate_trivariate_probit(data, config)
% Estimate a trivariate probit model via simulated maximum likelihood
% using a full covariance matrix Sigma.
%
% Latent utilities:
%   y_{i,t}^* = \theta_{i,t} + \epsilon_{i,t}
%
% where \epsilon_{i,t} ~ N(0, I).
%
% Observed outcomes:
%   y_i,t = 1[y_{i,t}^* >= threshold_i],  t in {Q2, Q3, SG}.
%
% Probabilities are computed with the GHK method.
    
    % Draw quasi-random U[0,1]
    sim_draws = make_simulation_draws(config.sim_draws, ...
        config.halton_skip, config.use_antithetic);
    
    % Tabulate binary choice pattern groups from data
    pattern_data = build_pattern_groups(data);
    
    % Define objective function
    objective = @(theta) trivariate_probit_neg_loglik_cov(theta, ...
        pattern_data, sim_draws);
    
    % Define optimization initial values for means
    mean_threshold = mean(data.threshold);
    mu0 = [ ...
        mean_threshold + norminv_clip(mean(data.y_q2)); ...
        mean_threshold + norminv_clip(mean(data.y_q3)); ...
        mean_threshold + norminv_clip(mean(data.y_last))];
    

    % Cholesky parameterization:
    % L = [ exp(a11)     0         0
    %       l21      exp(a22)      0
    %       l31         l32    exp(a33) ]
    %
    % theta = [mu(3); a11; l21; a22; l31; l32; a33]
    %
    % Start from Sigma = I
    theta0 = [mu0; 0; 0; 0; 0; 0; 0];
    

    % Optimization here
    parameter_names = { ...
        'mu_q2', 'mu_q3', 'mu_sg', ...
        'logL11', 'L21', 'logL22', 'L31', 'L32', 'logL33'};

    options = optimoptions('fminunc', ...
        'Algorithm', 'quasi-newton', ...
        'Display', 'iter', ...
        'MaxFunctionEvaluations', 8e4, ...
        'MaxIterations', 4e3, ...
        'OptimalityTolerance', 1e-8, ...
        'StepTolerance', 1e-10);

    [theta_hat, negLogLik, exitflag, output, grad, hessian] = ...
        fminunc(objective, theta0, options);
    

    % Save results
    natural = unpack_natural_parameters_cov(theta_hat);

    results = struct();
    results.theta0 = theta0(:);
    results.theta_hat = theta_hat(:);
    results.parameter_names = parameter_names;
    results.negLogLik = negLogLik;
    results.exitflag = exitflag;
    results.output = output;
    results.gradient = grad;
    results.hessian = hessian;
    results.halton_skip = config.halton_skip;
    results.use_antithetic = config.use_antithetic;
    results.pattern_data = pattern_data;
    results.mu = natural.mu;    % mu vector
    results.Sigma = natural.Sigma;  % covariance matrix
    results.corr = natural.corr;    % implied correlations


    % Compute standard error by delta method
    if ~isempty(hessian) && all(isfinite(hessian(:))) && rcond(hessian) > 1e-12
        vcov = inv(hessian);
        se_theta = sqrt(max(diag(vcov), 0));

        jac = numerical_jacobian(@(x) pack_natural_vector_cov( ...
            unpack_natural_parameters_cov(x)), theta_hat);

        vcov_natural = jac * vcov * jac';
        se_natural = sqrt(max(diag(vcov_natural), 0));

        results.vcov = vcov;
        results.se_theta = se_theta;
        results.vcov_natural = vcov_natural;
        results.se_natural = se_natural;

        results.se_mu_q2 = se_natural(1);
        results.se_mu_q3 = se_natural(2);
        results.se_mu_sg = se_natural(3);

        results.se_var_q2 = se_natural(4);
        results.se_var_q3 = se_natural(5);
        results.se_var_sg = se_natural(6);

        results.se_cov_q2_q3 = se_natural(7);
        results.se_cov_q2_sg = se_natural(8);
        results.se_cov_q3_sg = se_natural(9);
    else
        results.vcov = [];
        results.se_theta = [];
        results.vcov_natural = [];
        results.se_natural = [];

        results.se_mu_q2 = NaN;
        results.se_mu_q3 = NaN;
        results.se_mu_sg = NaN;

        results.se_var_q2 = NaN;
        results.se_var_q3 = NaN;
        results.se_var_sg = NaN;

        results.se_cov_q2_q3 = NaN;
        results.se_cov_q2_sg = NaN;
        results.se_cov_q3_sg = NaN;
    end
end





% Tabulate each binary choice pattern group from data
function pattern_data = build_pattern_groups(data)
    pattern_matrix = [data.threshold, data.y_q2, data.y_q3, data.y_last];
    [unique_patterns, ~, group_idx] = unique(pattern_matrix, 'rows', 'stable');

    counts = accumarray(group_idx, 1);

    pattern_data = struct();
    pattern_data.threshold = unique_patterns(:, 1);
    pattern_data.y = unique_patterns(:, 2:4);
    pattern_data.sign = 2 * unique_patterns(:, 2:4) - 1;
    pattern_data.count = counts(:);
    pattern_data.num_patterns = size(unique_patterns, 1);
end



% Negative loglikelihood function
function nll = trivariate_probit_neg_loglik_cov(theta, pattern_data, sim_draws)
    natural = unpack_natural_parameters_cov(theta);
    like = zeros(pattern_data.num_patterns, 1);

    for g = 1:pattern_data.num_patterns
        threshold_g = pattern_data.threshold(g);
        sign_g = pattern_data.sign(g, :)';

        mean_g = sign_g .* (natural.mu - threshold_g);
        flip = diag(sign_g);
        Sigma_g = flip * natural.Sigma * flip;

        p_g = ghk_positive_orthant_prob(mean_g, Sigma_g, sim_draws);
        like(g) = max(p_g, realmin);
    end

    nll = -sum(pattern_data.count .* log(like));
end



% Compute multivariate normal probability by the GHK method
function p = ghk_positive_orthant_prob(mu, Sigma, sim_draws)
    d = numel(mu);
    Sigma = (Sigma + Sigma') / 2;
    L = chol_with_jitter(Sigma);

    n = size(sim_draws, 1);
    eta = zeros(n, d);
    weights = ones(n, 1);

    for j = 1:d
        cond_mean = mu(j);
        if j > 1
            cond_mean = cond_mean + eta(:, 1:j-1) * L(j, 1:j-1)';
        end

        lower = -cond_mean / L(j, j);
        tail_prob = 1 - normal_cdf(lower);
        tail_prob = max(tail_prob, realmin);

        u = normal_cdf(lower) + tail_prob .* sim_draws(:, j);
        u = min(max(u, 1e-12), 1 - 1e-12);

        eta(:, j) = normal_inv(u);
        weights = weights .* tail_prob;
    end

    p = mean(weights);
    p = min(max(p, realmin), 1 - realmin);
end

function L = chol_with_jitter(Sigma)
    jitter = 0;
    eye_n = eye(size(Sigma));

    for attempt = 1:8
        if attempt == 1
            [L, flag] = chol(Sigma, 'lower');
        else
            [L, flag] = chol(Sigma + jitter * eye_n, 'lower');
        end

        if flag == 0
            return;
        end

        if jitter == 0
            jitter = 1e-10;
        else
            jitter = jitter * 10;
        end
    end

    error('Unable to compute a stable Cholesky factor for Sigma.');
end



% Derive the natural parameters from the optimization theta
function natural = unpack_natural_parameters_cov(theta)
    mu = theta(1:3);

    L = zeros(3,3);
    L(1,1) = exp(theta(4));
    L(2,1) = theta(5);
    L(2,2) = exp(theta(6));
    L(3,1) = theta(7);
    L(3,2) = theta(8);
    L(3,3) = exp(theta(9));

    Sigma = L * L';
    Sigma = (Sigma + Sigma') / 2;

    sd = sqrt(diag(Sigma));
    corr = Sigma ./ (sd * sd');

    natural = struct();
    natural.mu = mu(:);
    natural.L = L;
    natural.Sigma = Sigma;
    natural.corr = corr;
end

function vec = pack_natural_vector_cov(natural)
    vec = [ ...
        natural.mu(:); ...
        natural.Sigma(1,1); ...
        natural.Sigma(2,2); ...
        natural.Sigma(3,3); ...
        natural.Sigma(1,2); ...
        natural.Sigma(1,3); ...
        natural.Sigma(2,3)];
end



% 
function J = numerical_jacobian(fun, theta)
    f0 = fun(theta);
    n_out = numel(f0);
    n_in = numel(theta);
    J = zeros(n_out, n_in);

    for k = 1:n_in
        step = 1e-6 * max(1, abs(theta(k)));
        theta_plus = theta;
        theta_minus = theta;
        theta_plus(k) = theta_plus(k) + step;
        theta_minus(k) = theta_minus(k) - step;

        f_plus = fun(theta_plus);
        f_minus = fun(theta_minus);
        J(:, k) = (f_plus - f_minus) / (2 * step);
    end
end



% Quasi-random draws from U[0,1] i.e. Halton sequence
function draws = make_simulation_draws(n_draws, skip, use_antithetic)
    base_draws = halton_matrix(n_draws, 3, skip);
    if use_antithetic
        draws = [base_draws; 1 - base_draws];
    else
        draws = base_draws;
    end

    draws = min(max(draws, 1e-12), 1 - 1e-12);
end

function draws = halton_matrix(n, dim, skip)
    primes = [2, 3, 5, 7, 11, 13, 17, 19];
    draws = zeros(n, dim);
    for j = 1:dim
        draws(:, j) = radical_inverse_sequence(n, primes(j), skip);
    end
end

function seq = radical_inverse_sequence(n, base, skip)
    seq = zeros(n, 1);
    for idx = 1:n
        seq(idx) = radical_inverse(idx + skip, base);
    end
end

function x = radical_inverse(index, base)
    x = 0;
    f = 1 / base;
    i = index;

    while i > 0
        x = x + f * mod(i, base);
        i = floor(i / base);
        f = f / base;
    end
end



% Normal CDF and inverse functions 
function p = normal_cdf(x)
    p = 0.5 * erfc(-x ./ sqrt(2));
end

function x = normal_inv(p)
    x = sqrt(2) * erfinv(2 * p - 1);
end

function z = norminv_clip(p)
    p = min(max(p, 1e-8), 1 - 1e-8);
    z = normal_inv(p);
end
