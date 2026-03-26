function ll = ll_part1_b(x, A, match, min_match, max_match, id, min_id, max_id, strg_M, K)

% ll: negative of loglikelihood
% part1: part 1 decribed in estimation_strategy.tex

% input

% x are estimates 1x(K+1): [gamma, p_2]
% A: 1 = cooperate, 0 = defect
% match: indicates the match, > 0
% min_match: = min(match)
% max_match: = max(match)
% id: subject specific identifier
% min_id: = min(id)
% max_id: = max(id)
% strg_M: Matrix with each colum giving a different machine. Each row gives the choice that machine would make. 
% K: Number of machines considered - 1

% output

% -loglikelihood
%--------------------------------------------------------------------------

x = real(x);

gamma = x(1,1);
if gamma <= 0, gamma = 1e-2; end

if max(x(2:end,1)) >= 1, foo = x(2:end,1); foo(find(foo>=1))=0.999999999; x(2:end,1)=foo; end
if min(x) < 0, foo = x; foo(find(foo<0))=0.000000001; x=foo; end

% computations begin
p_im = x(2,1) * ll_im_b(gamma,A, match, min_match, max_match, id, min_id, max_id, strg_M(:,1));
if K > 2
    for i = 2:K-1
       j = i+1;
       p_im = x(j,1) * ll_im_b(gamma,A, match, min_match, max_match, id, min_id, max_id, strg_M(:,i)) + p_im;
    end
end
if K >= 2
    p_im = (1 - sum(x([2:end],1))) * ll_im_b(gamma,A, match, min_match, max_match, id, min_id, max_id, strg_M(:,K)) + p_im;
end

p_im(find(p_im==0))=realmin;

ll = -sum(log(p_im));
ll = real(ll);
