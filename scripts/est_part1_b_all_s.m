% Disable warnings
warning off all

% Loop over full data, first 5 and last 5
suffixes = {"", "_first5", "_last5"};

for s = 1:length(suffixes)

    suffix = suffixes{s};
    
    % Loop through the treatments
    parfor filenum = 1:8
        
        format long;
        
        input_filename = sprintf('dfformatlab_strg_%d%s_special.txt', filenum, suffix);
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
        strg = All(:, [9:end]);

    
        % Generate new vars
        max_id = max(id_all);
        min_id = min(id_all);
        K = size(strg, 2);
        % for i = min_id:max_id
        %     max_match(i) = max(match(find(id_all == i)));
        %     min_match(i) = min(match(find(id_all == i)));
        % end
        max_match = 0; min_match = 0;
    
        % Optimization
        rand('state', 123456789);
        [x, ll, hess, exitflag] = opt_part1_b(coop_all, match, min_match, max_match, id_all, min_id, max_id, strg, K, 0);
        for m = 1:20
            disp(m);
            start_foo = rand(K, 1);
            start_foo(2:end, 1) = start_foo(2:end, 1) / sum(start_foo);
            [x_foo, ll_foo, hess_foo, exitflag_foo] = opt_part1_b(coop_all, match, min_match, max_match, id_all, min_id, max_id, strg, K, start_foo);
            if ll_foo <= ll && exitflag_foo ~= 0
                x = x_foo; ll = ll_foo; hess = hess_foo; exitflag = exitflag_foo;
            end
        end

        % Play with results
        gamma = x(1, 1);

        % Negative values should be interpreted as near zero (see ll_part1_b)
        p = x([2:end], 1);
        p(K, 1) = 1 - sum(x([2:end], 1));
    
        % Bootstrapping the variance-covariance matrix
        start_bs = 0;
        [x_M, vc_bs] = dfbs_b(coop_all, match, id_all, strg, K, start_bs, session, 100);
        disp(vc_bs);
    
        % Wald tests (this part suffers from the problem that the cov is positive semidefinite rather than positive definite)
        % Uncomment the following lines if you have the waldtest function available
        % sqrt(diag(vc_bs))
        
        % Add a tiny variance if positive semidefinite
        min_eig = min(eig(vc_bs));
        if min_eig < 1e-15
            vc_bs = vc_bs + 1e-15 * eye(size(vc_bs));
        end
        
        % Initialize arrays to store the results
        h_values = zeros(1, 7);
        p_values = zeros(1, 7);
    
        % Perform Wald tests and store the results
        disp('alpha = 0');
        [h_values(1), p_values(1)] = waldtest(x(1), [1 0 0 0 0 0], vc_bs);
    
        disp('p(1) = 0');
        [h_values(2), p_values(2)] = waldtest(x(2), [0 1 0 0 0 0], vc_bs);
    
        disp('p(2) = 0');
        [h_values(3), p_values(3)] = waldtest(x(3), [0 0 1 0 0 0], vc_bs);
    
        disp('p(3) = 0');
        [h_values(4), p_values(4)] = waldtest(x(4), [0 0 0 1 0 0], vc_bs);
    
        disp('p(4) = 0');
        [h_values(5), p_values(5)] = waldtest(x(5), [0 0 0 0 1 0], vc_bs);
    
        disp('p(5) = 0');
        [h_values(6), p_values(6)] = waldtest(x(6), [0 0 0 0 0 1], vc_bs);
    
        disp('p(6) = 0');
        [h_values(7), p_values(7)] = waldtest(sum(x(2:6))-1, [0 1 1 1 1 1], vc_bs);
    
        % Display the stored results
        disp('h values:');
        disp(h_values);
        disp('p values:');
        disp(p_values);
    
        % Save the results
        output_filename = sprintf('raw/est_part1_b_%d_s%s.mat', filenum, suffix);
    
        S = struct();
        S.gamma = gamma;
        S.p = p;
        S.ll = ll;
        S.vc_bs = vc_bs;
        S.h_values = h_values;
        S.p_values = p_values;
        
        disp(size(S))   % should be [1 1]
        save(output_filename, '-fromstruct', S);

    end

end
