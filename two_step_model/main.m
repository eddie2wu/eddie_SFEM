
perfect_quiz = true;
t_step_one = 1;
% t_step_two = 3;

run_step_one(t_step_one, perfect_quiz);
% run_step_two(t_step_two, perfect_quiz);





%%
treatment = 2;

config = struct();
config.data_file = 'data/eddie_repeatedgamedata_sfem.csv';
config.use_perfect_quiz_only = true;
config.quad_nodes = 20;
config.cooperate_label = 'A';
config.output_mat_file = sprintf('result/step_one_results_t%d.mat', treatment);
config.Gamma = [32, 32, 32, 32, 32, 32];


data = preprocess_data(config, treatment);


% Loop over time
disp("==================================================================")
for tt = 1:max(data.match)

    temp = data.y(data.match == tt);
    fprintf("The mean cooperation in period %d is %.4f \n", tt, mean(temp));

end

fprintf("MEAN TREATMENT COOPERATION IS %.4f \n", mean(data.y));








% Plot
T = max(data.match);

mean_coop = zeros(T,1);

% Compute mean cooperation by period

for tt = 1:T

    temp = data.y(data.match == tt);

    mean_coop(tt) = mean(temp);

end

% Time index

time = (1:T)';

% Fit linear model: y = b1*x + b0

p = polyfit(time, mean_coop, 1);

% Predicted line

y_fit = polyval(p, time);

% Plot

figure;

scatter(time, mean_coop, 60, 'filled');

hold on;

plot(time, y_fit, 'LineWidth', 2);

xlabel('Time Period');

ylabel('Mean Cooperation');

title('Mean Cooperation Over Time');

legend('Mean Cooperation', 'Linear Fit');

grid on;

%%
[vals, idx] = maxk(results.lambda_F, 10);
disp(vals);
disp(idx);


%%

idx = data.id_index == 58;
y = data.y(idx);
disp(mean(y));
fprintf("exp(MU)\n")
disp(exp(results.mu(1:2)));
fprintf("SIGMA\n")
disp(results.sigma(1:2));
disp(results.lambda_V(58));
disp(results.phi(58));
disp(results.lambda_F(58));






%%

filename = "result/txt/step_one_results_t1_mu.txt";
t1_mu = readmatrix(filename);

filename = "result/txt/step_one_results_t1_lambda_F.txt";
t1_lambda_F = readmatrix(filename);

filename = "result/txt/step_one_results_t1_lambda_V.txt";
t1_lambda_V = readmatrix(filename);

filename = "result/txt/step_one_results_t1_phi.txt";
t1_phi = readmatrix(filename);



filename = "result/txt/step_one_results_t2_mu.txt";
t2_mu = readmatrix(filename);

filename = "result/txt/step_one_results_t2_lambda_F.txt";
t2_lambda_F = readmatrix(filename);

filename = "result/txt/step_one_results_t2_lambda_V.txt";
t2_lambda_V = readmatrix(filename);

filename = "result/txt/step_one_results_t2_phi.txt";
t2_phi = readmatrix(filename);


Gamma = 32;

ratio_t1 = mean( (50-Gamma) - t1_mu .* (Gamma - 25) ) / mean(t1_lambda_F + t1_phi + t1_lambda_V);

ratio_t2 = mean( (50-Gamma) - t2_mu .* (Gamma - 25) ) / mean(t2_lambda_F + t2_phi + t2_lambda_V);

disp(ratio_t1);
disp(ratio_t2);

fprintf("The mean of mu for t1 is %.4f\n", mean(t1_mu));
fprintf("The mean of mu for t2 is %.4f\n", mean(t2_mu));



