% simulates behavior from learning model
% uses estimates from same treatment

% % creating a diary
% delete('simul_t.out');
% diary('simul_t.out');
format long;

% set the number of simulated sessions
simul = 1000;
% set the number of matches
%%%%%%%%%%%% 70 matches per session for delta=0.5 and 32 per session for
%%%%%%%%%%%% delta = 0.75
T = 1000;
% set the number of subjects per session
% (the mean was 14.78)
S = 14;

% load the data
est = load( 'learningestimatesall.txt' );
% est is the following matrix [treat, id, delta, lamda_f, lambda_v, psi, betaAD_1, betaG_1, ll]
treat_all = est(:, 1);
id2_all = est(:, 2);
delta_all = est(:, 3);
lamda_f_all = est(:, 4);
lamda_v_all = est(:, 5);
psi_all = est(:, 6);
betaAD_1_all = est(:, 7);
betaG_1_all = est(:, 8);

% sets the state (seed) of the random number generator
rand('state',12345);

% create the variables that give the average payoff for every possibility
% uADAD = [100,50,100,50,100,100];
% uADG = [125,75,125,75,125,125];
% uGAD = [87,37,87,37,87,87];
% uGG = [128,64,128,64,160,160];
uADAD = [50,100,50,100,100,100,100,100];
uADG = [75,125,75,125,125,125,125,125];
uGAD = [37,87,37,87,87,87,87,87];
uGG = [64,128,64,128,128,128,192,192];


% initialize vars
choice = [];
fractions = [0:1/14:1];
counter = [];

% start of computations
for treat = 1:8
    % initialize vars
    choice_treat = zeros(T,1);
    delta_treat = delta_all(treat_all==treat);
    lamda_f_treat = lamda_f_all(treat_all==treat);
    lamda_v_treat = lamda_v_all(treat_all==treat);
    psi_treat = psi_all(treat_all==treat);
    betaAD_1_treat = betaAD_1_all(treat_all==treat);
    betaG_1_treat = betaG_1_all(treat_all==treat);
    id2_treat = id2_all(treat_all==treat);
    counter_treat = zeros(T,15);
    % S = size(id2_treat, 1);
    
    %%% Need to store a tensor i,j,k, where i is simulation, j is time, k
    %%% is subject. 
    beta_G_tensor = zeros(simul, 3, S);
    beta_AD_tensor = zeros(simul, 3, S);

    for i = 1:simul
        % initialize vars
        choice_simul = -999*ones(T,S);
        types = randsample(max(id2_treat),S,'true');   % this draws the id
        % of the subjects that will be used with replacement, S is going to
        % be the session size. 'true' indicates that the random draws are
        % made with replacement
        delta = delta_treat(types)'; % this works b/c id2 are sorted
        % these are row vectors
        lamda_f = lamda_f_treat(types)';
        lamda_v = lamda_v_treat(types)';
        psi = psi_treat(types)';
        betaAD = betaAD_1_treat(types)';
        betaG = betaG_1_treat(types)';
        e = rand(T, S);    e = -log( (1./e) - 1 );  % this generates random
        % numbers with a logistic distribution (mean 0, variance 1)
      

        for t = 1:T
            % generate the pairs of players
            matchup = [floor(randsample(S,S,'false')/2 + 0.5)]'; % this
            %  draws pairs of subjects. 'false' indicates that the random
            %  draws are made without replacement.
            % probabilities assigned to each possibilities
            pAD_j = betaAD./(betaAD+betaG);
            pG_j = betaG./(betaAD+betaG);
            % expected utilities
            EUAD = pAD_j*uADAD(treat) + pG_j*uADG(treat);
            EUG = pAD_j*uGAD(treat) + pG_j*uGG(treat);
            for subject = 1:S
                % predicted choices: 1 = G, 0 = AD
                choice_simul(t,subject) = (EUG(1,subject) - EUAD(1,subject) + (lamda_f(1,subject)+(lamda_v(1,subject)*(psi(1,subject)^(t-1))))*e(t,subject) > 0);
            end
            for subject = 1:S
                % update the beliefs
                if choice_simul(t,subject) == 0
                    % following if sums the choice of pairs of
                    % subjects and tells us what was chosen
                    if sum(choice_simul(t,find(matchup==matchup(1,subject)))) == 0
                        betaAD(1,subject) = delta(1,subject)*betaAD(1,subject) + 1;
                        betaG(1,subject) = delta(1,subject)*betaG(1,subject);
                    else
                        betaAD(1,subject) = delta(1,subject)*betaAD(1,subject);
                        betaG(1,subject) = delta(1,subject)*betaG(1,subject) + 1;
                    end
                else
                   % following if sums the choice of pairs of
                   % subjects and tells us what was chosen
                   if sum(choice_simul(t,find(matchup==matchup(1,subject)))) == 1
                        betaAD(1,subject) = delta(1,subject)*betaAD(1,subject) + 1;
                        betaG(1,subject) = delta(1,subject)*betaG(1,subject);
                    else
                        betaAD(1,subject) = delta(1,subject)*betaAD(1,subject);
                        betaG(1,subject) = delta(1,subject)*betaG(1,subject) + 1;
                    end
                end
            end
            

            %%% Append
            if t == 30
                beta_G_tensor(i,1,1:S) = betaG;
                beta_AD_tensor(i,1,1:S) = betaAD;
            elseif t == 60
                beta_G_tensor(i,2,1:S) = betaG;
                beta_AD_tensor(i,2,1:S) = betaAD;
            elseif t == 1000
                beta_G_tensor(i,3,1:S) = betaG;
                beta_AD_tensor(i,3,1:S) = betaAD;
            end
            

        end


        % add the choices across subjects and divide by number of subjects;
        choice_simul = sum(choice_simul,2) / S;
        % count where thi ssession falls in terms of behavior
        for pdb = 1:T
            counter_treat(pdb,find(choice_simul(pdb)+eps>fractions&choice_simul(pdb)-eps<fractions))=counter_treat(pdb,find(choice_simul(pdb)+eps>fractions&choice_simul(pdb)-eps<fractions)) + 1;
        end
        % add the choices across simulations
        choice_treat = choice_treat + choice_simul;
        
        % Print progress
        if mod(i, 20) == 0
            fprintf('treat = %d, i = %d\n', treat, i);
        end
    end


    %%%%% Reshape and save as txt file for this treatment
    beta_G_tensor = reshape(permute(beta_G_tensor, [1 3 2]), [], 3);
    beta_AD_tensor = reshape(permute(beta_AD_tensor, [1 3 2]), [], 3);
    save(sprintf('beta_G_treatment_%d.txt', treat), 'beta_G_tensor', '-ascii', '-double', '-tabs');
    save(sprintf('beta_AD_treatment_%d.txt', treat), 'beta_G_tensor', '-ascii', '-double', '-tabs');



    % divide the choices by number of simultaions (to get probabilities)
    choice_treat = choice_treat / simul;
    % stack the choices by treatment and put treatment number in front
    choice = [choice; treat*ones(T,1), [1:T]', choice_treat];
    % stack counter across treatments
    counter = [counter; counter_treat];
end
choice = [choice, counter]

save('simulationresults.txt', 'choice', '-ascii', '-double', '-tabs')

% Create an indicator file at the end of the script
fid = fopen('done.txt', 'w');
fclose(fid);

% diary off



