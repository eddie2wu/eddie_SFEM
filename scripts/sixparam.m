function ll = sixparam(x,A,OA,uADAD,uADG,uGAD,uGG)

% input

% x are estimates 6x1: [beta^AD, beta^G, delta=theta in text, lamda_f, lambda_v, psi]
% A is subject i's action (subject for which the loglik is being estimated)
% OA are subject j's action (subjects with whom i is paired)
% uADAD, uADG, uGAD, uGG give the payoffs to each of those strategies tuplet
%   where the first is i's strategy and the second j's strategy

% output

% loglikelihood
%--------------------------------------------------------------------------

% Transform delta to be in [0,1]
delta = 1/(1 + exp(x(3,1)));
%if delta < 1e-14
%    delta = 1e-14;
%end

% Transform lamda, and the beliefs to be positive and phi
betaAD_1 =exp(x(1,1));
betaG_1 = exp(x(2,1));
lamda_v = exp(x(4,1));
lamda_f = exp(x(5,1));
psi = 1/(1 + exp(x(6,1)));
% these next 2 ifs are necessary b/c Stata can't read numbers bigger than
% that.
if betaAD_1 > 6.6e+305
    ll = NaN;
    return
end
if betaG_1 > 6.6e+305
    ll = NaN;
    return
end

% computations begin
strength_1 = betaAD_1 + betaG_1;
T = length(A);

strength = zeros(T,1); % Given deltama, this is how the strength updates (i.e., denominator)
lamda = zeros(T,1); % this is how the lamda updates
strength(1,1) = strength_1;
lamda(1,1) = lamda_f + lamda_v * psi;
for i = 2:T
    strength(i,1) = delta*strength(i-1,1) + 1;
    lamda(i,1) = lamda_f + (lamda_v *( psi^(i)));
end

AD = [OA(1:T,1) == 0]; % Opponent chose an action consistent with AD
G = [OA(1:T,1) == 1]; % Opponent chose an action consistent with G

% This part updates the beliefs
pAD_j(1,1) = betaAD_1/strength_1; % initial probabilities
pG_j(1,1) = betaG_1/strength_1;
        
for i = 2:T
   pAD_j(i,1) = (delta*strength(i-1,1)*pAD_j(i-1,1) + AD(i-1,1))/strength(i,1); %Updated probabilities
   pG_j(i,1) = (delta*strength(i-1,1)*pG_j(i-1,1) + G(i-1,1))/strength(i,1);
end

% this part computes the expected utility of each choice at each point in
% time
EUAD = pAD_j*uADAD + pG_j*uADG;
EUG = pAD_j*uGAD + pG_j*uGG;

% this computes the loglikelihood
% gets a NaN if the part over which the log is taken would
% be 0
if sum((((exp((1./lamda).*EUAD)./(exp((1./lamda).*EUAD)+exp((1./lamda).*EUG))).^(1-A)).*...
    (((exp((1./lamda).*EUG))./(exp((1./lamda).*EUAD)+exp((1./lamda).*EUG))).^(A)))==0) ~= 0
    ll = NaN;
else
    ll = -sum(log(((exp((1./lamda).*EUAD)./(exp((1./lamda).*EUAD)+exp((1./lamda).*EUG))).^(1-A)).*...
        (((exp((1./lamda).*EUG))./(exp((1./lamda).*EUAD)+exp((1./lamda).*EUG))).^(A))));
end


