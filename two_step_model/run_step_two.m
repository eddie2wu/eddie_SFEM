function results = run_step_two(treatment, perfect_quiz)
% Step 2
    
    % Define step one results file
    if ismember(treatment, [4, 5, 6])
        step_one_treatment = 2;
    else
        step_one_treatment = 1;
    end

    % Define configs
    config = struct();
    config.data_file = 'data/eddie_repeatedgamedata_sfem.csv';
    config.step_one_results_file = sprintf('result/step_one_results_t%d.mat', step_one_treatment);
    config.use_perfect_quiz_only = perfect_quiz;
    config.quad_nodes = 20;
    config.cooperate_label = 'A';
    config.output_mat_file = sprintf('result/step_two_results_t%d.mat', treatment);
    config.Gamma = [32, 32, 32, 32, 32, 32];
    
    % Preprocess data
    data = preprocess_data(config, treatment);

    % Obtain optimization results
    results = estimate_step_two(data, config);

    % Save results
    save(config.output_mat_file, 'results', 'config');
    
    fprintf('\nStep two estimation finished.\n');
    fprintf('Alpha distribution estimated using treatment: %d\n', step_one_treatment);
    fprintf('Step two estimated using treatment: %d\n', treatment);
    fprintf('Number of subjects kept: %d\n', data.N);
    fprintf('Used perfect_quiz == 1 only: %d\n', config.use_perfect_quiz_only);
    
    fprintf('\nExit flags\n');
    fprintf('exitflag by subject: %d\n', results.exitflag);
    
    fprintf('\nParameter estimates\n');
    fprintf('beta_D  = % .6f\n', results.beta_D(1:20));
    fprintf('beta_C  = % .6f\n', results.beta_C(1:20));
    fprintf('learning_theta  = % .6f\n', results.learning_theta(1:20));
    fprintf('phi = % .6f\n', results.phi(1:20));
    fprintf('lambda_F   = % .6f\n', results.lambda_F(1:20));
    fprintf('lambda_V   = % .6f\n', results.lambda_V(1:20));
    
    fprintf('negLogLik = % .6f\n', results.total_negLogLik);
    
end

