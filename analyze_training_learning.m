function training_summary = analyze_training_learning(data_filepath, output_directory)
% Visualizes learning curves from the training phase.
%
%   This function analyzes performance across repeated visits to trials
%   during the training phase (stages 2 and 3) and plots the learning
%   curves for the 'awake' and 'sleep' groups.
%
%   SYNTAX:
%       training_summary = analyze_training_learning(data_filepath, output_directory)
%
%   DESCRIPTION:
%       1. Loads the final data table containing all trials from all subjects.
%       2. Filters for training data only.
%       3. For each subject, it identifies unique training pairs (e.g., A-B)
%          and numbers the chronological attempts for each pair (Visit 1, 2, 3...).
%       4. It first calculates the mean performance for each subject at each
%          visit number (averaging across all pairs).
%       5. It then calculates the group-level mean and SEM for each visit number.
%       6. It generates and saves one figure for each of the 4 key
%          performance measures (errors, angle error, path
%          efficiency, speed), showing the learning curves for both groups.
%
%   Example Usage:
%       data_file = 'E:\results\all_subjects_data_with_groups.mat';
%       out_dir   = 'E:\results\training_learning_analysis';
%       summary_data = analyze_training_learning(data_file, out_dir);


close all;

%% --- 1. Configuration & Data Loading ---
if ~exist(output_directory, 'dir')
    mkdir(output_directory);
end
if ~exist(data_filepath, 'file')
    error('Input data file not found: %s', data_filepath);
end
fprintf('Loading data from: %s\n', data_filepath);
load(data_filepath, 'final_table');

%% --- 2. Data Pre-processing ---
fprintf('Pre-processing data...\n');

final_table.speed = final_table.length ./ final_table.duration;
final_table.speed(isinf(final_table.speed) | isnan(final_table.speed)) = NaN;
final_table.abs_angle_error = abs(final_table.angle_error);
final_table.group = categorical(final_table.group);

% Filter for valid training data
training_data = final_table(final_table.teststage < 4 & ~isundefined(final_table.group), :);

%% --- 3. Create a "Visit Number" for Repeated Trials ---
fprintf('Numbering visits to each unique training pair...\n');

% Create a unique, direction-independent ID for each pair (e.g., A-B is same as B-A)
pair_fields = sort([training_data.StartField, training_data.GoalField], 2);
training_data.PairID = categorical(strcat(string(pair_fields(:,1)), '-', string(pair_fields(:,2))));

subjects = unique(training_data.subject);
training_data_renumbered = [];

for i = 1:numel(subjects)
    subj_id = subjects{i};
    subject_data = training_data(strcmp(training_data.subject, subj_id), :);
    unique_pairs = unique(subject_data.PairID);
    
    for p = 1:numel(unique_pairs)
        current_pair = unique_pairs(p);
        
        % Get all trials for this subject and this pair
        pair_trials = subject_data(subject_data.PairID == current_pair, :);
        
        % Sort chronologically and assign visit number
        pair_trials = sortrows(pair_trials, 'trial');
        pair_trials.VisitNum = (1:height(pair_trials))';
        
        training_data_renumbered = [training_data_renumbered; pair_trials];
    end
end
fprintf('Renumbering complete.\n\n');

%% --- 4. Calculate Per-Subject and Group-Level Statistics ---
fprintf('Calculating statistics for learning curves...\n');

measures_to_summarize = {'errors', 'abs_angle_error', 'path_efficiency', 'speed'};

% Step 1: Get the mean for each SUBJECT at each visit number (averaging across pairs)
subject_means_by_visit = groupsummary(training_data_renumbered, {'subject', 'group', 'VisitNum'}, 'mean', measures_to_summarize);

% Step 2: Get the group-level stats from the per-subject means
grouping_vars = {'group', 'VisitNum'};
training_summary = groupsummary(subject_means_by_visit, grouping_vars, {'mean', 'std', 'numel'}, strcat('mean_', measures_to_summarize));

% Calculate SEM
for m = 1:numel(measures_to_summarize)
    measure = measures_to_summarize{m};
    training_summary.(['sem_' measure]) = training_summary.(['std_mean_' measure]) ./ sqrt(training_summary.GroupCount);
end

disp('Summary table for plotting:');
disp(training_summary);

%% --- 5. Generate Plots ---
fprintf('Generating training learning curve plots...\n');

plot_measures = measures_to_summarize; % Use the same list as defined earlier
plot_titles = {'Number of Errors', 'Absolute Angle Error', 'Path Efficiency', 'Speed'};
y_labels = {'Mean Errors', 'Mean Abs Angle Error', 'Mean Path Efficiency', 'Mean Speed'};
group_colors = [0.2157, 0.4941, 0.7216; 0.8941, 0.1020, 0.1098]; % awake (blue), sleep (red)
group_names = unique(training_summary.group);
group_names = sort(group_names);

for p = 1:length(plot_measures)
    measure = plot_measures{p};
    mean_col = ['mean_mean_' measure];
    sem_col = ['sem_' measure];
    
    fig = figure('Position', [100, 100, 800, 600]);
    hold on;
    
    legend_handles = [];
    for g = 1:numel(group_names)
        current_group = group_names(g);
        
        % Filter summary data for this group
        data_to_plot = training_summary(training_summary.group == current_group, :);
        
        if ~isempty(data_to_plot)
            x_vals = data_to_plot.VisitNum;
            y_vals = data_to_plot.(mean_col);
            sem_vals = data_to_plot.(sem_col);
            
            % Plot the mean line
            h = plot(x_vals, y_vals, '-o', 'Color', group_colors(g,:), ...
                'LineWidth', 2, 'MarkerFaceColor', 'w');
            legend_handles(g) = h;
            
            % Plot the shaded error region
            fill([x_vals; flipud(x_vals)], [y_vals-sem_vals; flipud(y_vals+sem_vals)], ...
                group_colors(g,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        end
    end
    
    hold off;
    grid on; box on;
    title(['Learning Curve during Training: ' plot_titles{p}], 'FontSize', 16);
    xlabel('Visit Number to Trial Pair', 'FontSize', 12);
    ylabel(y_labels{p}, 'FontSize', 12);
    
    max_visits = max(training_summary.VisitNum);
    if ~isempty(max_visits) && max_visits > 0
        xlim([0.5, max_visits + 0.5]);
        set(gca, 'XTick', 1:max_visits);
    end
    
    % Find the overall maximum y-value for this measure across both groups
    % We add the mean and SEM to find the top of the error band
    all_means = training_summary.(mean_col);
    all_sems = training_summary.(sem_col);
    y_max_val = max(all_means + all_sems, [], 'omitnan') * 1.1; % Add 10% padding
    
    % Handle cases with no data or zero values
    if isnan(y_max_val) || y_max_val == 0
        y_max_val = 1;
    end
    
    % Set the Y-axis limits
    ylim([0, y_max_val]);
    
    legend(legend_handles, cellstr(group_names), 'Location', 'best');
    
    % Save the figure
    figure_title_for_save = strrep(plot_titles{p}, ' ', '_');
    figure_filename = fullfile(output_directory, ['training_learning_curve_' lower(figure_title_for_save) '.png']);
    print(fig, figure_filename, '-dpng', '-r300');
    fprintf('  - Saved figure to %s\n', figure_filename);
    output_xlsx = fullfile(output_directory, 'learning_training_summary.xlsx');
    writetable(training_summary, output_xlsx);
end

fprintf('Summary table saved as %s\n', output_xlsx);
fprintf('All plots generated and saved.\n\n');
end