function [x_M, vc_bs] = dfbs_b(A, match, id, strg_M, K, start, session, reps)


% generate new vars
min_session = min(session);
max_session = max(session);
s_val = [min_session:max_session]';
foo = ones(size(match));

% start loop to compute estimates
x_M = [];
rand('state', 123456789);
for i = 1:reps
    m = 0;
    match_bs = [];
    coop_all_bs = [];
    strg_M_bs = [];
    id2_bs = [];
    for j = 1:size(s_val,1)    % 3 b/c there are 3 sessions per treatment
        s_bs = randsample(s_val, 1, 'true');
        id_bs = id(session == s_bs);
        for k = 1:length(unique(id_bs))  % 20, 22 or 24  b/c there are about 20, 22 or 24 subjects per session
            m = m+1;
            s_i_bs = randsample(id_bs, 1, 'true');
            match_bs = [match_bs; match(id == s_i_bs)];
            coop_all_bs = [coop_all_bs; A(id == s_i_bs)];
            strg_M_bs = [strg_M_bs; strg_M(id == s_i_bs,:)];
            id2_bs = [id2_bs; m*foo(id == s_i_bs)];  % this generates a different id for the same subject if he is randomly re-selected
        end
    end
    max_id_bs = max(id2_bs);
    min_id_bs = min(id2_bs);    
    % for l = min_id_bs:max_id_bs
    %     max_match_bs(l) = max(match_bs(find(id2_bs==l)));
    %     min_match_bs(l) = min(match_bs(find(id2_bs==l)));
    % end
    max_match_bs = 0; min_match_bs = 0;
    
    % optimization
    [x, ll, hess, exitflag] = opt_part1_b(coop_all_bs, match_bs, min_match_bs, max_match_bs, id2_bs, min_id_bs, max_id_bs, strg_M_bs, K, start);
    for m = 1:3
        start_foo = rand(K,1); start_foo(2:end, 1) = start_foo(2:end, 1)/sum(start_foo);
        [x_foo, ll_foo, hess_foo, exitflag_foo] = opt_part1_b(coop_all_bs, match_bs, min_match_bs, max_match_bs, id2_bs, min_id_bs, max_id_bs, strg_M_bs, K, start_foo);
        if ll_foo <= ll & exitflag_foo ~= 0
            x = x_foo; ll = ll_foo; hess = hess_foo; exitflag = exitflag_foo;
        end
    end
    if exitflag == 0, x_M = x_M; else, x_M = [x_M, x]; end;
    i
end

% variance-covariance
vc_bs = cov(x_M');
