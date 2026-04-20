function results = run_baseline_logit()
% Baseline hierarchical logit for:
%   1. Q2 
%   2. Q3 
%   3. All choices in each subject's last supergame
%
% Assumptions in this baseline:
%   - Keep only treatments 7 and 19.
%   - Optionally keep only perfect_quiz == 1 subjects.
%   - Drop subjects with missing Q3.
%   - Map A = cooperate, B = defect.
%   - Use task-specific representation parameters beta_t.
%   - Use task-specific logistic scale parameters s_t.
%
% Identification normalization:
%   beta_SG = beta_last = 0
%
% The estimated parameter vector is:
%   theta = [mu_theta, log_sigma_theta, beta_q2, beta_q3, ...
%            log_s_q2, log_s_q3, log_s_last]
    
    % Define configs
    Gamma = [32, 32];
    config = struct();
    config.data_file = 'data/eddie_repeatedgamedata_sfem.csv';
    config.use_perfect_quiz_only = true;
    config.quad_nodes = 50;
    config.cooperate_label = 'A';
    config.output_mat_file = 'result/baseline_logit_results.mat';
    config.threshold = log( (50-Gamma) ./ (Gamma-25) );


    % Preprocess data
    data = preprocess_data(config);
    
    % Estimate parameter
    results = estimate_baseline_logit(data, config);
    
    % Save results
    save(config.output_mat_file, 'results', 'config');
    
    fprintf('\nBaseline hierarchical logit finished.\n');
    fprintf('Number of subjects kept: %d\n', data.N);
    fprintf('Used perfect_quiz == 1 only: %d\n', config.use_perfect_quiz_only);
    fprintf('\nParameter estimates\n');
    fprintf('mu_theta  = % .6f\n', results.mu_theta);
    fprintf('sigma_th  = % .6f\n', results.sigma_theta);
    fprintf('beta_q2   = % .6f\n', results.beta_q2);
    fprintf('beta_q3   = % .6f\n', results.beta_q3);
    fprintf('beta_last = % .6f  (fixed normalization)\n', results.beta_last);
    fprintf('s_q2      = % .6f\n', results.s_q2);
    fprintf('s_q3      = % .6f\n', results.s_q3);
    fprintf('s_last    = % .6f\n', results.s_last);
    fprintf('negLogLik = % .6f\n', results.negLogLik);
end
