function results = estimate_step_two(data, config)

    % Get dimensions
    T = data.T;
    N = data.N;
    
    % Load step one mu and sigma
    step_one_results = load(config.step_one_results_file, 'results').results;
    mu_alpha = step_one_results.mu;
    sigma_alpha = step_one_results.sigma;

    % Check whether mu and sigma length same as data length
    if length(mu_alpha) ~= T || length(sigma_alpha) ~= T
        error('mu_alpha and sigma_alpha must both be T x 1.');
    end

    % Quadrature nodes
    [nodes, weights] = gauss_hermite_rule(config.quad_nodes);

    % Store output
    ID_all = unique(data.id);
    theta_hat_all = zeros(N, 6);
    negLogLik_all = zeros(N, 1);
    exitflag_all = zeros(N, 1);
    output_all = cell(N, 1);

    param_names = { ...
        'log_beta_D', ...
        'log_beta_C', ...
        'raw_theta', ...
        'raw_phi', ...
        'log_lambda_F', ...
        'log_lambda_V' ...
    };
    
    % Optimization for each individual
    for i = 1:N

        fprintf('Estimating Step 2 for subject %d / %d...\n', i, N);
        
        % Get data for this individual
        ID = ID_all(i);
        idx = (data.id == ID);
        yi = data.y(idx);
        yi_ap = data.y_ap(idx);
        

        % Define objective function
        objective = @(theta) subject_negloglik( ...
            theta, yi, yi_ap, data.Gamma, mu_alpha, sigma_alpha, nodes, weights);
        

        % Run optimization
        theta0 = get_starting_values();

        options = optimoptions('fminunc', ...
                'Display', 'off', ...
                'Algorithm', 'quasi-newton', ...
                'MaxIterations', 5000, ...
                'MaxFunctionEvaluations', 20000, ...
                'OptimalityTolerance', 1e-6, ...
                'StepTolerance', 1e-8);

        [theta_hat, negLogLik, exitflag, output] = fminunc(objective, theta0, options);


        % Save optimization results for subject i
        theta_hat_all(i, :) = theta_hat(:)';
        negLogLik_all(i) = negLogLik;
        exitflag_all(i) = exitflag;
        output_all{i} = output;

    end
    
    
    % -------------------------
    % Unpack parameters and save results
    % -------------------------
    
    beta_D_hat = exp(theta_hat_all(:, 1));
    beta_C_hat = exp(theta_hat_all(:, 2));
    learning_theta_hat = stable_logit(theta_hat_all(:, 3));
    phi_hat = stable_logit(theta_hat_all(:, 4));
    lambda_F_hat = exp(theta_hat_all(:, 5));
    lambda_V_hat = exp(theta_hat_all(:, 6));
    
    % Save results
    results = struct();
    results.theta_raw = theta_hat_all;
    results.parameter_names_raw = param_names;

    results.beta_D = beta_D_hat;
    results.beta_C = beta_C_hat;
    results.learning_theta = learning_theta_hat;
    results.phi = phi_hat;
    results.lambda_F = lambda_F_hat;
    results.lambda_V = lambda_V_hat;

    results.negLogLik_by_subject = negLogLik_all;
    results.total_negLogLik = sum(negLogLik_all);

    results.exitflag = exitflag_all;
    results.output = output_all;

end



function nll = subject_negloglik(theta, yi, yi_ap, Gamma, mu, sigma, nodes, weights)
    
    T = length(yi);

    % Transform unconstrained parameters
    beta_D = exp(theta(1));
    beta_C = exp(theta(2));
    learning_theta = stable_logit(theta(3));   

    phi = stable_logit(theta(4));   
    lambda_F = exp(theta(5));
    lambda_V = exp(theta(6));

    loglik = 0;

    
    for t = 1:T

        % Current belief that opponent is AD
        b = beta_D / (beta_D + beta_C);

        % Avoid b = 1 because the term b / (1-b) explodes
        b = min(max(b, 1e-10), 1 - 1e-10);

        % Define lambda_t
        lambda_t = lambda_F + (phi ^ t) * lambda_V;

        % Integrate P(AD) over alpha_t
        log_alpha_nodes = mu(t) + sqrt(2) * sigma(t) * nodes;
        alpha_nodes = exp(log_alpha_nodes);

        Delta = (50 - Gamma) + ...
                    (13 * b)/(1-b) - ...
                    alpha_nodes * (Gamma - 25);
        z = Delta ./ lambda_t;
        
        p_defect_nodes = stable_logit(z);

        p_defect = (weights' * p_defect_nodes) / sqrt(pi);
        p_defect = min(max(p_defect, 1e-12), 1 - 1e-12);


        % Update loglikelihood 
        if yi(t) == 1
            loglik = loglik + log(p_defect);
        else
            loglik = loglik + log(1 - p_defect);
        end


        % Update beliefs after observing autoplayer's action in supergame t
        if yi_ap(t) == 1

            % Autuplayer plays CC
            beta_D = learning_theta * beta_D;
            beta_C = learning_theta * beta_C + 1;
            
        else

            % Autolpayer plays AD
            beta_D = learning_theta * beta_D + 1;
            beta_C = learning_theta * beta_C;
            
        end
        
        beta_D = max(beta_D, 1e-12);
        beta_C = max(beta_C, 1e-12);

    end

    nll = -loglik;
end




function theta0 = get_starting_values()
% Starting values on unconstrained scale.
% 
% beta_D = exp(0) = 1
% beta_C = exp(0) = 1
% learning_theta = sigmoid(0) = 0.5
% phi = sigmoid(0) = 0.5
% lambda_F = exp(log(1)) = 1
% lambda_V = exp(log(1)) = 1

    theta0 = zeros(6, 1);
    theta0(1) = log(1);    % beta_D
    theta0(2) = log(1);    % beta_C
    theta0(3) = 0;         % learning theta
    theta0(4) = 0;         % phi
    theta0(5) = log(1);    % lambda_F
    theta0(6) = log(1);    % lambda_V

end

