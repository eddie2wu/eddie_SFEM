function results = run_trivariate_probit(treatment)
% Trivariate model estimated via multivariate probit with simulated max
% likelihood.
%
% Relative to the baseline model:
%   - subject i has task-specific latent components
%       theta_i = [theta_i,Q2, theta_i,Q3, theta_i,SG]'
%   - there are no task-specific beta's
%   - observed cooperation is governed by a trivariate normal latent index
%
% Identification note:
%   Cannot identify epsilon + theta, so let epsilon be standard normal, and
%   theta absorbs all the covariances etc.
    
    % Define configs
    Gamma = [32, 32];

    config = struct();
    config.data_file = 'data/eddie_repeatedgamedata_sfem.csv';
    config.use_perfect_quiz_only = true;
    config.cooperate_label = 'A';
    config.threshold = log((50 - Gamma) ./ (Gamma - 25));

    config.output_mat_file = sprintf('result/trivariate_probit_results_t%d.mat', treatment);
    config.sim_draws = 2000;
    config.halton_skip = 100;
    config.use_antithetic = true;


    % Preprocess data
    data = preprocess_data(config, treatment);

    % Estimate parameters
    results = estimate_trivariate_probit(data, config);
    
    % Make dir and save
    output_dir = fileparts(config.output_mat_file);
    if ~isempty(output_dir) && ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    save(config.output_mat_file, 'results', 'config');

    % Print results
    fprintf('\nTrivariate latent probit finished.\n');
    fprintf('Using treatment: %d\n', treatment);
    fprintf('Number of subjects kept: %d\n', data.N);
    fprintf('Used perfect_quiz == 1: %d\n', config.use_perfect_quiz_only);

    fprintf('\nMu parameters\n');
    fprintf('mu_q2     = % .6f', results.mu(1));
    print_se(results.se_mu_q2);
    fprintf('mu_q3     = % .6f', results.mu(2));
    print_se(results.se_mu_q3);
    fprintf('mu_sg     = % .6f', results.mu(3));
    print_se(results.se_mu_sg);

    fprintf('\nCovariance matrix\n');
    fprintf('Sigma_q2^2 = % .6f', results.Sigma(1,1));
    print_se(results.se_var_q2);
    fprintf('Sigma_q3^2 = % .6f', results.Sigma(2,2));
    print_se(results.se_var_q3);
    fprintf('Sigma_sg^2 = % .6f', results.Sigma(3,3));
    print_se(results.se_var_sg);
    fprintf('Sigma_q2_q3 = % .6f', results.Sigma(2,1));
    print_se(results.se_cov_q2_q3);
    fprintf('Sigma_q2_sg = % .6f', results.Sigma(3,1));
    print_se(results.se_cov_q2_sg);
    fprintf('Sigma_q3_sg = % .6f', results.Sigma(3,2));
    print_se(results.se_cov_q3_sg);

    fprintf('\nnegLogLik = % .6f\n', results.negLogLik);
end


function print_se(se)
    if isnan(se)
        fprintf('               (se = NaN)\n');
    else
        fprintf('               (se = %.6f)\n', se);
    end
end
