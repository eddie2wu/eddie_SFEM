function results = run_step_one(treatment, perfect_quiz)

    config = struct();
    config.data_file = 'data/eddie_repeatedgamedata_sfem.csv';
    config.use_perfect_quiz_only = perfect_quiz;
    config.quad_nodes = 20;
    config.cooperate_label = 'A';
    config.output_mat_file = sprintf('result/step_one_small_iterative_results_t%d.mat', treatment);
    config.Gamma = [32, 32, 32, 32, 32, 32, 32, 32];
    config.max_outer_iter = 200;
    config.outer_tol = 1e-6;

    % number of random starts
    config.num_starts = 30;
    config.base_seed = 1234;

    % Preprocess data
    data = preprocess_data(config, treatment);

    % Get unique IDs
    [~, ~, data.id_index] = unique(data.id, 'stable');

    % -------------------------------------------------
    % Multiple random starts
    % -------------------------------------------------

    best_nll = Inf;
    best_results = [];

    all_nll = NaN(config.num_starts, 1);
    all_seeds = NaN(config.num_starts, 1);

    for s = 1:config.num_starts

        seed_s = config.base_seed + s;
        rng(seed_s);

        fprintf('\n====================================\n');
        fprintf('Random start %d / %d, seed = %d\n', ...
            s, config.num_starts, seed_s);
        fprintf('====================================\n');

        try
            results_s = estimate_step_one_small_iterative(data, config);
            all_nll(s) = results_s.negLogLik;
            all_seeds(s) = seed_s;
            
            fprintf('Finished start %d: NLL = %.8f\n', ...
                s, results_s.negLogLik);

            if isfinite(results_s.negLogLik) && results_s.negLogLik < best_nll
                best_nll = results_s.negLogLik;
                best_results = results_s;
                best_start = s;
                best_seed = seed_s;

                fprintf('New best solution found. NLL = %.8f\n', best_nll);

            end

        catch ME

            fprintf('Start %d failed with error:\n', s);
            fprintf('%s\n', ME.message);
            all_nll(s) = Inf;
            all_seeds(s) = seed_s;

        end

    end

    % Keep only the best result as main output
    results = best_results;

    % Store random-start summary, not every full result
    results.num_starts = config.num_starts;
    results.base_seed = config.base_seed;

    results.all_nll = all_nll;
    results.all_seeds = all_seeds;

    results.best_start = best_start;
    results.best_seed = best_seed;

    % Save only best results
    save(config.output_mat_file, 'results', 'config', 'data');

    % -------------------------------------------------
    % Print results
    % -------------------------------------------------

    fprintf('\nStep one iterative estimation finished.\n');
    fprintf('Using treatment: %d\n', treatment);
    fprintf('Number of subjects kept: %d\n', data.N);
    fprintf('Used perfect_quiz == 1 only: %d\n', config.use_perfect_quiz_only);

    fprintf('\nRandom start summary\n');
    fprintf('Number of starts: %d\n', config.num_starts);
    fprintf('Best start: %d\n', results.best_start);
    fprintf('Best seed: %d\n', results.best_seed);

    fprintf('\nParameter estimates from best start\n');
    fprintf('negLogLik = % .6f\n', results.negLogLik);
    
    fprintf('mu first 10 = \n');
    disp(results.mu(1:min(10,end)));
    
    fprintf('sigma first 10 = \n');
    disp(results.sigma(1:min(10,end)));

    fprintf('lambda_F first 10 = \n');
    disp(results.lambda_F(1:min(10,end)));

    fprintf('lambda_V first 10 = \n');
    disp(results.lambda_V(1:min(10,end)));

    fprintf('phi first 10 = \n');
    disp(results.phi(1:min(10,end)));

    fprintf('\nAll NLLs by random start:\n');
    disp(all_nll);

end




% function results = run_step_one(treatment, perfect_quiz)
% 
%     config = struct();
%     config.data_file = 'data/eddie_repeatedgamedata_sfem.csv';
%     config.use_perfect_quiz_only = perfect_quiz;
%     config.quad_nodes = 20;
%     config.cooperate_label = 'A';
%     config.output_mat_file = sprintf('result/step_one_small_iterative_results_t%d.mat', treatment);
%     config.Gamma = [32, 32, 32, 32, 32, 32, 32, 32];
%     config.max_outer_iter = 200;
%     config.outer_tol = 1e-6;
% 
% 
%     % Preprocess data
%     data = preprocess_data(config, treatment);
% 
%     % Get unique IDs
%     [~, ~, data.id_index] = unique(data.id, 'stable');
% 
%     % Param estimation
%     results = estimate_step_one_small_iterative(data, config);
% 
%     % Save results
%     save(config.output_mat_file, 'results', 'config', 'data');
% 
%     % Print results
%     fprintf('\nStep one iterative estimation finished.\n');
%     fprintf('Using treatment: %d\n', treatment);
%     fprintf('Number of subjects kept: %d\n', data.N);
%     fprintf('Used perfect_quiz == 1 only: %d\n', config.use_perfect_quiz_only);
% 
%     fprintf('\nParameter estimates\n');
%     fprintf('negLogLik = % .6f\n', results.negLogLik);
%     fprintf('mu first 10 = \n');
%     disp(results.mu(1:min(10,end)));
%     fprintf('sigma first 10 = \n');
%     disp(results.sigma(1:min(10,end)));
% 
%     fprintf('lambda_F first 10 = \n');
%     disp(results.lambda_F(1:min(10,end)));
%     fprintf('lambda_V first 10 = \n');
%     disp(results.lambda_V(1:min(10,end)));
%     fprintf('phi first 10 = \n');
%     disp(results.phi(1:min(10,end)));
% 
% end
% 
% 



% function results = run_step_one(treatment, perfect_quiz)
% % Step 1
% 
%     % Define configs
%     config = struct();
%     config.data_file = 'data/eddie_repeatedgamedata_sfem.csv';
%     config.use_perfect_quiz_only = perfect_quiz;
%     config.quad_nodes = 20;
%     config.cooperate_label = 'A';
%     config.output_mat_file = sprintf('result/step_one_results_t%d.mat', treatment);
%     config.Gamma = [32, 32, 32, 32, 32, 32];
% 
%     % Preprocess data
%     data = preprocess_data(config, treatment);
% 
%     % Obtain optimization results
%     results = estimate_step_one(data, config);
% 
%     % Save results
%     save(config.output_mat_file, 'results', 'config');
% 
%     fprintf('\nStep one estimation finished.\n');
%     fprintf('Using treatment: %d\n', treatment);
%     fprintf('Number of subjects kept: %d\n', data.N);
%     fprintf('Used perfect_quiz == 1 only: %d\n', config.use_perfect_quiz_only);
% 
%     fprintf('\nParameter estimates\n');
%     fprintf('mu  = % .6f\n', results.mu);
%     fprintf('sigma  = % .6f\n', results.sigma);
%     fprintf('lambda_F   = % .6f\n', results.lambda_F(1:10));
%     fprintf('lambda_V   = % .6f\n', results.lambda_V(1:10));
%     fprintf('phi = % .6f\n', results.phi(1:10));
%     fprintf('negLogLik = % .6f\n', results.negLogLik);
% 
% end
