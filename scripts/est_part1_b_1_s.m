% part1 refers to the description of the strategy in
% estimation strategy.tex

% when refering to machines, I use mijklm to indicate a machine that starts
% by i (0 = defect, 1 = coop), does j when mijklm[t-1] == 1 and ocoop[t-1] == 1
% (ocoop is the decision of the other player); does k when mijklm[t-1] == 1
% and ocoop[t-1] == 0, does l when mijklm[t-1] == 0 and ocoop[t-1] == 1,
% does m when mijklm[t-1] == 0 and ocoop[t-1] == 0

warning off all

% % creating a diary
% delete('c:\gfrechette\df\log\part1_b_1_s.out');
% diary('c:\gfrechette\df\log\part1_b_1_s.out');
format long;

% input data
clear
All = load( 'dfformatlab_strg_1_special.txt' );
match = All(:, 1);
round = All(:, 2);
treatment = All(:, 3);
coop_all = All(:, 4);
id_all = All(:, 5);
ocoop_all = All(:, 6);
p1 = 1;
p2 = 7;
strg = All(:,[7:end-2]); include = [1:6]; strg = strg(:, include);
% ad, ac, g, tft, wsls, t2
session = All(:, end-1);
id2_all = All(:, end);

% generate new vars
max_id = max(id_all);
min_id = min(id_all);
K = size(strg,2);
% for i = min_id:max_id
%     max_match(i) = max(match(find(id_all==i)));
%     min_match(i) = min(match(find(id_all==i)));
% end
max_match = 0; min_match = 0;


% optimization
rand('state', 123456789);
[x, ll, hess, exitflag] = opt_part1_b(coop_all, match, min_match, max_match, id_all, min_id, max_id, strg, K, 0);
disp("Starting the m loop");
for m = 1:20
    start_foo = rand(K,1); start_foo(2:end, 1) = start_foo(2:end, 1)/sum(start_foo);
    [x_foo, ll_foo, hess_foo, exitflag_foo] = opt_part1_b(coop_all, match, min_match, max_match, id_all, min_id, max_id, strg, K, start_foo);
    if ll_foo <= ll & exitflag_foo ~= 0
        x = x_foo; ll = ll_foo; hess = hess_foo; exitflag = exitflag_foo;
    end
    disp(m);
end

% play with results
gamma = x(1,1);
% negative values should be interpreted as near zero (see ll_part1_b)
p = x([2:end],1);
p(K,1) = 1 - sum(x([2:end],1));

% spiting out some data
output(1,:) = [ll gamma p'];
output;
ll
gamma
[include', p]

% Bootsrapping the variance-covariance matrix
start_bs = 0;  
              
[x_M, vc_bs] = dfbs_b(coop_all, match, id_all, strg, K, start_bs, session, 100);
vc_bs
sqrt(diag(vc_bs))
disp('alpha = 0');
waldtest(x, [1], 0, vc_bs);
disp('p(1) = 0');
waldtest(x, [2], 0, vc_bs);
disp('p(2) = 0');
waldtest(x, [3], 0, vc_bs);
disp('p(3) = 0');
waldtest(x, [4], 0, vc_bs);
disp('p(4) = 0');
waldtest(x, [5], 0, vc_bs);
disp('p(5) = 0');
waldtest(x, [6], 0, vc_bs);
disp('p(6) = 0');
waldtest(x, [0,1,1,1,1,1], [1], vc_bs);

save('raw/est_part1_b_1_s', 'gamma', 'p', 'll', 'vc_bs', '-double', '-tabs')
% diary off

