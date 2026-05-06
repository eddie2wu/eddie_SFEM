
clear; clc;


% ====== USER SETTINGS ======

treatment = 1;
in_dir = "result";
mat_file = sprintf("step_one_small_iterative_MC_results_t%d.mat", treatment);   % change this
out_dir  = "result/txt";  % output folder
struct_name = "results";             % change if your struct has another name

% ====== LOAD MAT FILE ======

S = load(fullfile(in_dir, mat_file));

if ~isfield(S, struct_name)
    error("Struct '%s' not found in %s", struct_name, mat_file);
end

results = S.(struct_name);

if ~exist(out_dir, "dir")
    mkdir(out_dir);
end


% ====== EXPORT EACH FIELD ======

fields = fieldnames(results);
for k = 1:numel(fields)
    fname = fields{k};
    value = results.(fname);
    out_file = fullfile(out_dir, erase(mat_file, ".mat") + "_" + fname + ".txt");

    if isnumeric(value) || islogical(value)

        writematrix(value, out_file, "Delimiter", "tab");

    elseif ischar(value) || isstring(value)

        fid = fopen(out_file, "w");
        fprintf(fid, "%s\n", string(value));
        fclose(fid);

    elseif iscell(value)

        writecell(value, out_file, "Delimiter", "tab");

    else

        % For nested structs or unsupported objects

        fid = fopen(out_file, "w");
        fprintf(fid, "%s\n", evalc("disp(value)"));
        fclose(fid);

    end

    fprintf("Saved %s\n", out_file);

end

fprintf("\nDone. Files saved in folder: %s\n", out_dir);
