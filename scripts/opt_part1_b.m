function [x, ll, hess, exitflag] = opt_part1_b(A, match, min_match, max_match, id, min_id, max_id, strg_M, K, start)

%%%%%%%%%
% Input %
%%%%%%%%%
% A: 1 = cooperate, 0 = defect
% match: indicates the match, > 0
% min_match: = min(match)
% max_match: = max(match)
% id: subject specific identifier
% min_id: = min(id)
% max_id: = max(id)
% strg_M: Matrix with each colum giving a different machine. Each row gives the choice that machine would make. 
% K: Number of machines considered - 1
% start: starting value of optimizer, 0 = smae for every machine, 1 =
% higher for more likely machines, o/w passed on directly a vector of
% starting values.

%%%%%%%%%%
% Output %
%%%%%%%%%%
% x: parameter estimates
% ll: log likelihood
% hess: Hessian

% transform variables
strg_M = -1*(strg_M==0)+(strg_M==1);

% change options for optimization
% new option command
MaxFunEvals = 100000;
options = optimset('MaxFunEvals',MaxFunEvals);
options = optimset('LargeScale', 'off');
%options = optimset('Display', 'iter');
options = optimset('Display', 'off');

% starting values
if start == 0, start_gamma = 0.352168543; start_p =  [1/(size(strg_M,2))*ones((size(strg_M,2)-1),1)];
elseif start == 1, start_gamma = 0.352168543; start_p = [0.2;((1-.8)/17)*ones(12,1);0.2;0.2;0.2];
else start_gamma = start(1,1); start_p = start(2:end,1);
end

% optimization
[x, ll, exitflag,OUTPUT,LAMBDA,GRAD,hess] = fmincon(@ll_part1_b,[start_gamma; start_p],[0,ones(1,size(strg_M,2)-1)],[1],[],[],[zeros(size(strg_M,2),1)],[Inf;ones(size(strg_M,2)-1,1)],[],options, A, match, min_match, max_match, id, min_id, max_id, strg_M, K);
