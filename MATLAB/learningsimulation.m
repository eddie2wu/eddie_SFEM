
format long;
rng(12345);

% Add path
project_root = fileparts(fileparts(mfilename('fullpath')));
intermediate_dir = fullfile(project_root, 'intermediate_output/learningmodel');


%%% Define autoplayer and sample
if ~exist('sample', 'var')
    sample = 'full';
end

if ~exist('autoplayer', 'var')
    autoplayer = true;
end



% ------------------------------------------------------------
% output filename
% ------------------------------------------------------------
if autoplayer
    autoplayer_tag = 'ap1';
else
    autoplayer_tag = 'ap0'
end

results_file = sprintf("simulationresults_%s_%s.txt", autoplayer_tag, sample);
betaG_prefix = sprintf("betaG_%s_%s_treatment_", autoplayer_tag, sample);
betaAD_prefix = sprintf("betaAD_%s_%s_treatment_", autoplayer_tag, sample);



%%% Specify settings
simul = 1000;   % no of simulations
T = 1000;   % no of rounds for each supergame
S = 14; % number of subjects drawn from a treatment group in each simulation

%%% create the variables that give the average payoff for every possibility
uADAD = [50,100,50,100,100,100,100,100];
uADG = [75,125,75,125,125,125,125,125];
uGAD = [37,87,37,87,87,87,87,87];
uGG = [64,128,64,128,128,128,192,192];


%%% Load data
est = load( fullfile(intermediate_dir, 'learningestimatesall.txt') );   % est is the following matrix [treat, id, delta, lamda_f, lambda_v, psi, betaAD_1, betaG_1, ll]
treat_all       = est(:, 1);
id2_all         = est(:, 2);
delta_all       = est(:, 3);
lamda_f_all     = est(:, 4);
lamda_v_all     = est(:, 5);
psi_all         = est(:, 6);
betaAD_1_all    = est(:, 7);
betaG_1_all     = est(:, 8);



% ------------------------------------------------------------
% DEFINE AUTOPLAYER COOPERATION PROBABILITY BY TREATMENT
% ------------------------------------------------------------
pA = zeros(8,1);
pA(1) = 1.00;
pA(2) = 1.00;
pA(3) = 0.14;
pA(4) = 0.31;
pA(5) = 0.31;
pA(6) = 0.31;
pA(7) = 0.83;
pA(8) = 0.83;


% ------------------------------------------------------------
% initialize storage
% ------------------------------------------------------------
choice = [];
fractions = 0:1/14:1;
counter = [];

% ------------------------------------------------------------
% start simulation
% ------------------------------------------------------------
for treat = 1:8
    
    choice_treat = zeros(T,1);

    delta_treat     = delta_all(treat_all==treat);
    lamda_f_treat   = lamda_f_all(treat_all==treat);
    lamda_v_treat   = lamda_v_all(treat_all==treat);
    psi_treat       = psi_all(treat_all==treat);
    betaAD_1_treat  = betaAD_1_all(treat_all==treat);
    betaG_1_treat   = betaG_1_all(treat_all==treat);
    id2_treat       = id2_all(treat_all==treat);
    
    counter_treat = zeros(T,15);
    
    % tensors to save beliefs at t = 30, 60, 1000
    beta_G_tensor  = zeros(simul, 3, S);
    beta_AD_tensor = zeros(simul, 3, S);
    
    for i = 1:simul
        
        % ----------------------------------------------------
        % draw S subjects with replacement from this treatment
        % ----------------------------------------------------
        choice_simul = -999 * ones(T,S);
        
        types = randsample(max(id2_treat), S, 'true');
        
        delta   = delta_treat(types)';
        lamda_f = lamda_f_treat(types)';
        lamda_v = lamda_v_treat(types)';
        psi     = psi_treat(types)';
        betaAD  = betaAD_1_treat(types)';
        betaG   = betaG_1_treat(types)';
        
        % logistic shocks
        e = rand(T,S);
        e = -log((1./e) - 1);
        
        % autoplay realized first-round choices for each supergame/subject
        % 1 = A = cooperate = G
        % 0 = B = defect    = AD
        if autoplayer
            OA = rand(T,S) < pA(treat);
        end

        for t = 1:T
            
            % probabilities assigned to each possibility
            pAD_j = betaAD ./ (betaAD + betaG);
            pG_j  = betaG  ./ (betaAD + betaG);
            
            % expected utilities
            EUAD = pAD_j * uADAD(treat) + pG_j * uADG(treat);
            EUG  = pAD_j * uGAD(treat)  + pG_j * uGG(treat);
            
            % predicted choices: 1 = G (cooperate), 0 = AD (defect)
            for subject = 1:S
                lam_t = lamda_f(1,subject) + lamda_v(1,subject) * (psi(1,subject)^(t-1));
                choice_simul(t,subject) = ...
                    (EUG(1,subject) - EUAD(1,subject) + lam_t * e(t,subject) > 0);
            end
            
            % update beliefs using autoplay first-round choice only
            % OA(t,subject)=1 means A/cooperate -> reinforces betaG
            % OA(t,subject)=0 means B/defect    -> reinforces betaAD
            if autoplayer
                % autoplay opponent update
                for subject = 1:S
                    if OA(t,subject) == 1
                        % opponent cooperated => reinforce betaG
                        betaAD(1,subject) = delta(1,subject) * betaAD(1,subject);
                        betaG(1,subject)  = delta(1,subject) * betaG(1,subject) + 1;
                    else
                        % opponent defected => reinforce betaAD
                        betaAD(1,subject) = delta(1,subject) * betaAD(1,subject) + 1;
                        betaG(1,subject)  = delta(1,subject) * betaG(1,subject);
                    end
                end

            else
                % real-player random matching update
                matchup = floor(randsample(S, S, false) / 2 + 0.5)';

                for subject = 1:S
                    partner_choices_sum = sum(choice_simul(t, matchup == matchup(1,subject)));

                    if choice_simul(t,subject) == 0
                        % subject played AD
                        if partner_choices_sum == 0
                            % pair outcome (AD,AD)
                            betaAD(1,subject) = delta(1,subject) * betaAD(1,subject) + 1;
                            betaG(1,subject)  = delta(1,subject) * betaG(1,subject);
                        else
                            % pair outcome (AD,G)
                            betaAD(1,subject) = delta(1,subject) * betaAD(1,subject);
                            betaG(1,subject)  = delta(1,subject) * betaG(1,subject) + 1;
                        end
                    else
                        % subject played G
                        if partner_choices_sum == 1
                            % pair outcome (G,AD)
                            betaAD(1,subject) = delta(1,subject) * betaAD(1,subject) + 1;
                            betaG(1,subject)  = delta(1,subject) * betaG(1,subject);
                        else
                            % pair outcome (G,G)
                            betaAD(1,subject) = delta(1,subject) * betaAD(1,subject);
                            betaG(1,subject)  = delta(1,subject) * betaG(1,subject) + 1;
                        end
                    end
                end
            
            end
            

            % save beliefs at selected times
            if t == 30
                beta_G_tensor(i,1,1:S)  = betaG;
                beta_AD_tensor(i,1,1:S) = betaAD;
            elseif t == 60
                beta_G_tensor(i,2,1:S)  = betaG;
                beta_AD_tensor(i,2,1:S) = betaAD;
            elseif t == 1000
                beta_G_tensor(i,3,1:S)  = betaG;
                beta_AD_tensor(i,3,1:S) = betaAD;
            end
            
        end
        
        % -----------------------------------------------
        % aggregate to fraction choosing G in this session
        % -----------------------------------------------
        choice_simul_mean = sum(choice_simul, 2) / S;
        
        % count where each session falls among fractions 0,1/14,...,1
        for pdb = 1:T
            idx = find(choice_simul_mean(pdb) + eps > fractions & ...
                       choice_simul_mean(pdb) - eps < fractions);
            counter_treat(pdb, idx) = counter_treat(pdb, idx) + 1;
        end
        
        % add across simulations
        choice_treat = choice_treat + choice_simul_mean;
        
        if mod(i,20) == 0
            fprintf('Using autoplayer = %d, treat = %d, i = %d\n', autoplayer, treat, i);
        end
        
    end
    
    % -----------------------------------------------
    % save belief tensors for this treatment
    % -----------------------------------------------
    beta_G_tensor  = reshape(permute(beta_G_tensor,  [1 3 2]), [], 3);
    beta_AD_tensor = reshape(permute(beta_AD_tensor, [1 3 2]), [], 3);
    
    betaG_result_file = fullfile(intermediate_dir, sprintf('%s%d.txt', betaG_prefix, treat));
    save( betaG_result_file, ...
         'beta_G_tensor', '-ascii', '-double', '-tabs');
    betaAD_result_file = fullfile(intermediate_dir, sprintf('%s%d.txt', betaAD_prefix, treat));
    save( betaAD_result_file, ...
         'beta_AD_tensor', '-ascii', '-double', '-tabs');

    
    % average over simulations
    choice_treat = choice_treat / simul;
    
    % stack output
    choice = [choice; treat * ones(T,1), (1:T)', choice_treat];
    counter = [counter; counter_treat];
    
end

choice = [choice, counter];
save( fullfile(intermediate_dir, results_file), 'choice', '-ascii', '-double', '-tabs');

