% Disable warnings
warning off all

if ~exist('sample', 'var')
    sample = 'full';
end

if ~exist('numStrat', 'var')
    numStrat = 3;
end

project_root = fileparts(fileparts(mfilename('fullpath')));
intermediate_dir = fullfile(project_root, 'intermediate_output/strat_used');
addpath(intermediate_dir);

if ~exist(intermediate_dir, 'dir')
    mkdir(intermediate_dir);
end


% Loop over full data, dropped 1st quarter, first 5 and last 5
suffixes = {"", "_drop1qtr", "_first5", "_last5"};
% suffixes = {"_first5", "_last5"};

for s = 1:length(suffixes)

    suffix = suffixes{s};

    % Loop through the treatments
    parfor filenum = 1:8

        format long;
        input_filename = fullfile(intermediate_dir, ...
            sprintf('dfformatlab_strat%d_%d%s_%s.txt', numStrat, filenum, suffix, sample));
        disp(input_filename)

        All = load(input_filename);
        match = All(:, 1);
        round = All(:, 2);
        treatment = All(:, 3);
        coop_all = All(:, 4);
        id_all = All(:, 5);
        ocoop_all = All(:, 6);
        session = All(:, 7);
        id_all = All(:, 8); % using the relative id rather than the absolute id
        strg = All(:, 9:end);

        % Generate new vars
        max_id = max(id_all);
        min_id = min(id_all);
        K = size(strg, 2);
        % for i = min_id:max_id
        %     max_match(i) = max(match(find(id_all == i)));
        %     min_match(i) = min(match(find(id_all == i)));
        % end
        max_match = 0;
        min_match = 0;

        % Optimization
        rand('state', 123456789);
        [x, ll, hess, exitflag] = opt_part1_b(coop_all, match, min_match, max_match, id_all, min_id, max_id, strg, K, 0);
        for m = 1:20    
            disp(m);
            start_foo = rand(K, 1);
            start_foo(2:end, 1) = start_foo(2:end, 1) / sum(start_foo);
            [x_foo, ll_foo, hess_foo, exitflag_foo] = opt_part1_b(coop_all, match, min_match, max_match, id_all, min_id, max_id, strg, K, start_foo);
            if ll_foo <= ll && exitflag_foo ~= 0
                x = x_foo;
                ll = ll_foo;
                hess = hess_foo;
                exitflag = exitflag_foo;
            end
        end

        % Play with results
        gamma = x(1, 1);

        % Negative values should be interpreted as near zero (see ll_part1_b)
        p = x(2:end, 1);
        p(K, 1) = 1 - sum(x(2:end, 1));

        % Bootstrapping the variance-covariance matrix
        start_bs = 0;
        [x_M, vc_bs] = dfbs_b(coop_all, match, id_all, strg, K, start_bs, session, 100);
        disp(vc_bs);

        % Wald tests (this part suffers from the problem that the cov is positive
        % semidefinite rather than positive definite)
        min_eig = min(eig(vc_bs));
        if min_eig < 1e-15
            vc_bs = vc_bs + 1e-15 * eye(size(vc_bs));
        end

        [test_labels, test_values, test_vectors] = get_strategy_config(K, x);
        strategy_tag = sprintf('S%d', K);

        h_values = zeros(1, numel(test_labels));
        p_values = zeros(1, numel(test_labels));

        for test_idx = 1:numel(test_labels)
            disp(test_labels{test_idx});
            [h_values(test_idx), p_values(test_idx)] = waldtest(test_values(test_idx), test_vectors{test_idx}, vc_bs);
        end

        disp('h values:');
        disp(h_values);
        disp('p values:');
        disp(p_values);
        
        output_filename = fullfile(intermediate_dir, sprintf('est_part1_b_%s_%d%s_%s.mat', strategy_tag, filenum, suffix, sample));

        S = struct();
        S.gamma = gamma;
        S.p = p;
        S.ll = ll;
        S.vc_bs = vc_bs;
        S.h_values = h_values;
        S.p_values = p_values;

        disp(size(S)) % should be [1 1]
        save(output_filename, '-fromstruct', S);

    end

end

function [test_labels, test_values, test_vectors] = get_strategy_config(K, x)
    if K == 6
        test_labels = {'alpha = 0', 'p(1) = 0', 'p(2) = 0', 'p(3) = 0', 'p(4) = 0', 'p(5) = 0', 'p(6) = 0'};
        test_values = [x(1), x(2), x(3), x(4), x(5), x(6), sum(x(2:6)) - 1];
        test_vectors = {
            [1 0 0 0 0 0], ...
            [0 1 0 0 0 0], ...
            [0 0 1 0 0 0], ...
            [0 0 0 1 0 0], ...
            [0 0 0 0 1 0], ...
            [0 0 0 0 0 1], ...
            [0 1 1 1 1 1]
        };
    elseif K == 3
        test_labels = {'alpha = 0', 'p(1) = 0', 'p(2) = 0', 'p(3) = 0'};
        test_values = [x(1), x(2), x(3), sum(x(2:3)) - 1];
        test_vectors = {
            [1 0 0], ...
            [0 1 0], ...
            [0 0 1], ...
            [0 1 1]
        };
    else
        error('Unsupported number of strategies: %d. Expected 3 or 6.', K);
    end
end

