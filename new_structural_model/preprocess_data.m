function data = preprocess_data(config, treatment)
% Process data for all treatments:
%   y_q2(i)       : binary answer for Q2 / complexity_answer
%   y_q3(i)       : binary answer for Q3 / length_answer
%   y_last(i)     : first-round binary choice in the last supergame
%   treatment(i)  : rename treatment number
%                    7  -> 1
%                    19 -> 2
%                    9 -> 3
%                    21 -> 4
%                    15 -> 5
%                    20 -> 6
%                    23 -> 7
%                    24 -> 8
%   threshold(i)  : treatment-specific threshold
    
    T = readtable(config.data_file, 'TextType', 'string');
    
    % Rename original treatment
    old = [7 19 9  21 15 20 23 24];
    new = [1 2  3  4  5  6  7  8];
    [tf, loc] = ismember(T.treatment, old);
    T.treatment = new(loc)';

    % Keep only the treatment needed
    T = T(T.treatment == treatment, :);

    % Whether using perfect quiz
    if config.use_perfect_quiz_only
        T = T(T.perfect_quiz == 1, :);
    end

    subject_ids = unique(T.id);

    kept_ids = [];
    treatment_vec = [];
    perfect_quiz_vec = [];
    threshold_vec = [];
    y_q2 = [];
    y_q3 = [];
    y_last = [];
    last_match = [];

    for i = 1:numel(subject_ids)

        sid = subject_ids(i);
        Ti = sortrows(T(T.id == sid, :), {'match', 'round'});

        last_match_i = max(Ti.match);
        Tlast = Ti(Ti.match == last_match_i, :);
        Tlast = sortrows(Tlast, 'round');

        first_round_choice = Tlast.player_choice(1);
        
        treat_i = Ti.treatment(1);
        
        kept_ids(end + 1, 1) = sid; 
        treatment_vec(end + 1, 1) = treat_i;
        perfect_quiz_vec(end + 1, 1) = Ti.perfect_quiz(1); 
        threshold_vec(end + 1, 1) = config.threshold(treat_i);
        y_q2(end + 1, 1) = double(Ti.complexity_answer(1) == config.cooperate_label); 
        y_q3(end + 1, 1) = double(Ti.length_answer(1) == config.cooperate_label); 
        y_last(end + 1, 1) = double(first_round_choice == config.cooperate_label); 
        last_match(end + 1, 1) = last_match_i; 
    end

    data = struct();
    data.id = kept_ids;
    data.treatment = treatment_vec;
    data.perfect_quiz = perfect_quiz_vec;
    data.threshold = threshold_vec;
    data.y_q2 = y_q2;
    data.y_q3 = y_q3;
    data.y_last = y_last;
    data.last_match = last_match;
    data.N = numel(kept_ids);

    if data.N == 0
        error('No subjects left after preprocessing.');
    end
end
