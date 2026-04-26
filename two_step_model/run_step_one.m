function results = run_step_one(treatment, perfect_quiz)
% Step 1
    
    % Define configs
    config = struct();
    config.data_file = 'data/eddie_repeatedgamedata_sfem.csv';
    config.use_perfect_quiz_only = perfect_quiz;
    config.quad_nodes = 50;
    config.cooperate_label = 'A';
    config.output_mat_file = sprintf('result/step_one_results_t%d.mat', treatment);
    config.Gamma = [32, 32, 32, 32, 32, 32];

    % Preprocess data
    data = preprocess_data(config, treatment);

    % Obtain optimization results
    results = estimate_step_one(data, config);

    % Save results
    save(config.output_mat_file, 'results', 'config');
    
    fprintf('\nStep one estimation finished.\n');
    fprintf('Using treatment: %d\n', treatment);
    fprintf('Number of subjects kept: %d\n', data.N);
    fprintf('Used perfect_quiz == 1 only: %d\n', config.use_perfect_quiz_only);

    fprintf('\nParameter estimates\n');
    fprintf('mu  = % .6f\n', results.mu);
    fprintf('sigma  = % .6f\n', results.sigma);
    fprintf('lambda_F   = % .6f\n', results.lambda_F(1:10));
    fprintf('lambda_V   = % .6f\n', results.lambda_V(1:10));
    fprintf('phi = % .6f\n', results.phi(1:10));
    fprintf('negLogLik = % .6f\n', results.negLogLik);

end
