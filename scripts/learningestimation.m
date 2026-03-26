% file that estimates the learning model for "The Evolution of 
% Cooperation in Infinitely Repeated Games: Experimental Evidence"
 

% creating a diary
delete('learningestimation.out');
diary('learningestimation.out');
format long;

% input data
clear
All = load( 'dfformatlab.txt' );
match = All(:, 1);
treatment = All(:, 2);
coop_all = All(:, 3);
id_all = All(:, 4);
ocoop_all = All(:, 5);
id2_all = All(:, 6);

%% initialize var that saves the results
est = [];
tic = 0;

% create the variables that give the average payoff for every possibility
uADAD = [100,50,100,50,100,100];
uADG = [125,75,125,75,125,125];
uGAD = [87,37,87,37,87,87];
uGG = [128,64,128,64,160,160];

% change options for optimization
% new option command
MaxIter = 100;
MaxFunEvals = 100000;
options = optimset('MaxFunEvals',MaxFunEvals);

% initialize starting value matrix
start_mat = [0,0,0,0,0,0;0,0,-10,0,0,-10;0,0,10,0,0,10;1,0,0,0,0,0;0,1,0,0,0,0;0,0,10,0,0,-10;0,0,-10,0,0,10];
stop = length(start_mat);

% start of computations
for treat = 1:6
    %6
    coop_treat = coop_all(treatment==treat);
    ocoop_treat = ocoop_all(treatment==treat);
    id2_treat = id2_all(treatment==treat);
    id_treat = id_all(treatment==treat);
    for i = 1:max(id2_treat)
        tic = tic + 1;
        coop = coop_treat(id2_treat==i);
        ocoop = ocoop_treat(id2_treat==i);
        id = id_treat(id2_treat==i);
        ll_foo = 10000000000000;
        for s = 1:stop
            start_vec = start_mat(s,:);
            [x, ll, exitflag] = fminsearch(@sixparam,start_vec',options,coop,ocoop,uADAD(1,treat),uADG(1,treat),uGAD(1,treat),uGG(1,treat));
            if exitflag ~= 1 & s < stop;
                ll_foo = ll_foo;
            elseif exitflag == 1 & s < stop;
                if ll < ll_foo;
                    ll_foo = ll;
                    % recover the parameters of interests
                                delta = 1/(1 + exp(x(3,1)));
                                betaAD_1 = exp(x(1,1));
                                betaG_1 = exp(x(2,1));
                                lamda_v = exp(x(4,1));
                                lamda_f = exp(x(5,1));
                                psi = 1/(1 + exp(x(6,1)));
                    est(tic,:) = [treat, i, id(1), delta, lamda_f, lamda_v, psi, betaAD_1, betaG_1, ll];
                else exitflag == 1 & s < stop & ll > ll_foo;
                    ll_foo = ll_foo;
                end
            elseif s == stop;
                if ll < ll_foo;
                    if exitflag ~= 1 & ll_foo == 0;
                        disp('convergence problem');
                        % set estimates to 999
                        delta = 999;
                        lamda_f = 999;
                        lamda_v = 999;
                        betaAD_1 = 999;
                        betaG_1 = 999;
                        psi = 999;
                        est(tic,:) = [treat, i, id(1), delta, lamda_f, lamda_v, psi, betaAD_1, betaG_1, 999];
                    else;
                        % recover the parameters of interests
                           delta = 1/(1 + exp(x(3,1)));
                            betaAD_1 = exp(x(1,1));
                            betaG_1 = exp(x(2,1));
                            lamda_v = exp(x(4,1));
                            lamda_f = exp(x(5,1));
                            psi = 1/(1 + exp(x(6,1)));
                        est(tic,:) = [treat, i, id(1), delta, lamda_f, lamda_v, psi, betaAD_1, betaG_1, ll];
                    end
                end
            end
        end
    end
end
est

save('learningestimates.txt', 'est', '-ascii', '-double', '-tabs')

% Create an indicator file at the end of the script
fid = fopen('done.txt', 'w');
fclose(fid);

diary off
