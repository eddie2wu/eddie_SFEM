function data = preprocess_data(config, treatment)
% Keep the first round of each match for each subject.
%
% Output is a panel of subject ID and match (supergame) number:
%   data.id(i)             : subject ID
%   data.match(i)          : match number
%   data.treatment(i)      : renamed treatment number
%                            7  -> 1
%                            19 -> 2
%                            9  -> 3
%                            21 -> 4
%                            15 -> 5
%                            20 -> 6
%                            23 -> 7
%                            24 -> 8
%   data.perfect_quiz(i)   : perfect_quiz indicator
%   data.y(i)              : cooperation indicator
%   data.y_ap(i)           : cooperation indicator of autoplayer

    dt = readtable(config.data_file, 'TextType', 'string');

    % Rename original treatment
    old = [7 19 9  21 15 20 23 24];
    new = [1 2  3  4  5  6  7  8];
    [tf, loc] = ismember(dt.treatment, old);
    dt.treatment = new(loc)';

    % Keep only the treatment needed
    dt = dt(dt.treatment == treatment, :);

    % Whether using perfect quiz
    if config.use_perfect_quiz_only
        dt = dt(dt.perfect_quiz == 1, :);
    end
    
    % Keep only first round of each match for each ID.
    dt = dt(dt.round == 1, :);
    
    % Sort by id and match
    dt = sortrows(dt, {'id', 'match'});
    
    % Save as struct
    data = struct();
    data.id = dt.id;
    data.match = dt.match;
    data.treatment = dt.treatment;
    data.y = double(dt.player_choice == config.cooperate_label);
    data.y_ap = double(dt.computer_choice == config.cooperate_label);
    data.N = numel(unique(dt.id));
    data.T = max(dt.match);
    data.Gamma = config.Gamma(treatment);

end
