function data = preprocess_data(config)
% Build one observation block per subject:
%   y_q2(i)       : binary answer for Q2 / complexity_answer
%   y_q3(i)       : binary answer for Q3 / length_answer
%   y_last(i)     : first-round binary choice in the last supergame
%   treatment(i)  : rename treatment number
%                    original 7  -> 1
%                    original 19 -> 2
%   threshold(i)  : treatment-specific threshold

    T = readtable(config.data_file, 'TextType', 'string');

    keep_treatment = ismember(T.treatment, [7, 19]);
    T = T(keep_treatment, :);

    % Rename original treatment
    % 7 -> 1, 19 -> 2
    T.treatment(T.treatment == 7) = 1;
    T.treatment(T.treatment == 19) = 2;

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

        q3_nonmissing = Ti.length_answer(Ti.length_answer ~= "");
        if any(ismissing(q3_nonmissing))
            continue;
        end

        q2_nonmissing = Ti.complexity_answer(Ti.complexity_answer ~= "");
        if any(ismissing(q2_nonmissing))
            continue;
        end

        q2_unique = unique(q2_nonmissing);
        q3_unique = unique(q3_nonmissing);

        if numel(q2_unique) ~= 1
            error('Subject %g has inconsistent Q2 answers.', sid);
        end
        if numel(q3_unique) ~= 1
            error('Subject %g has inconsistent Q3 answers.', sid);
        end

        last_match_i = max(Ti.match);
        Tlast = Ti(Ti.match == last_match_i, :);
        Tlast = sortrows(Tlast, 'round');

        if isempty(Tlast)
            continue;
        end

        first_round_choice = Tlast.player_choice(1);
        if ismissing(first_round_choice) || first_round_choice == ""
            continue;
        end

        treat_i = Ti.treatment(1);

        if ~(treat_i >= 1 && treat_i <= numel(config.threshold))
            error('Treatment index %g is out of range for config.threshold.', treat_i);
        end

        kept_ids(end + 1, 1) = sid; 
        treatment_vec(end + 1, 1) = treat_i;
        perfect_quiz_vec(end + 1, 1) = Ti.perfect_quiz(1); 
        threshold_vec(end + 1, 1) = config.threshold(treat_i);
        y_q2(end + 1, 1) = double(q2_unique == config.cooperate_label); 
        y_q3(end + 1, 1) = double(q3_unique == config.cooperate_label); 
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

