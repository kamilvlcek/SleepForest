function [change_summary_table, stats_table, intermediate_table] = calculate_plot_memory_change(data_filepath, output_directory, plot_type, do_stats)
%   This function isolates specific training and test trials to calculate
%   a memory change score for each subject and visualizes the results
%
%   DESCRIPTION:
%       1. Loads the final data table from all subjects with groups
%       2. Filters for subjects in 'sleep' or 'awake' groups
%       3. For each subject, it finds the VERY FIRST Level 1 test trial for
%          the 'Statues' condition (aim A->JELENA) and the 'North'
%          condition (aim I->TUCNAKA)
%       4. Finds all training trials for these specific aims
%       5. Creates an intermediate table with this subset of data
%       6. Calculates a baseline by averaging the LAST 2 training trials
%          for each aim
%       7. Calculates a change score (Test - Training Baseline) for 4
%          key performance measures
%       8. Returns a final summary table with one row per subject
%       9. Generates plots showing the change from training to test for
%          each subject, grouped by condition
%
%    Inputs:
%       data_filepath: The full path to the .mat file of final data table with groups (all_subjects_data_with_groups.mat)
%
%       output_directory: The full path to the folder where the output summary tables and figures will be saved
%
%       plot_type: Specifies the type of plot to generate:
%               0 - shows the direct change from Training to Test for each subject
%               1 - shows the summary (Mean/SEM) of the calculated change scores for each group with individual points
%
%       do_stats: 0/1 If 1, the function will perform the Mann-Whitney U tests on change and save the results
%
%    Outputs:
%           change_summary_table (table): The primary output table with one row per subject, containing training baselines, test performance, and calculated change scores (saved to xls)
%
%           stats_table (table): A table summarizing the results of the Mann-Whitney U tests (saved to the same xls file to the sheet 'Statistics')
%
%           intermediate_table (table): a long-format table with the raw trial data used for the calculations (saved to a separate xls)
%
%   Example Usage:
%       data_file = 'E:\results\all_subjects_data_with_groups.mat';
%       out_dir   = 'E:\results\memory_change_analysis';
%      [summary, stats] = calculate_plot_memory_change(data_file, out_dir, 1, 1);

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

%% --- 2. Data Pre-processing & Filtering ---
fprintf('Pre-processing and filtering data...\n');

% --- Pre-calculate measures ---
final_table.speed = final_table.length ./ final_table.duration;
final_table.speed(isinf(final_table.speed) | isnan(final_table.speed)) = NaN;
final_table.abs_angle_error = abs(final_table.angle_error);
final_table.group = categorical(final_table.group);

% --- Define the specific trials of interest ---
STATUES_TRIAL_TARGET = 'JELENA';
NORTH_TRIAL_TARGET = 'TUCNAKA';

% --- Filter for relevant data ---
% Only subjects in sleep/awake groups
data = final_table(ismember(final_table.group, {'sleep', 'awake'}), :);

% Find all training trials for the two aims of interest
training_statues_trials = data(data.teststage < 4 & strcmp(data.animal, STATUES_TRIAL_TARGET), :);
training_north_trials = data(data.teststage < 4 & strcmp(data.animal, NORTH_TRIAL_TARGET), :);

% Find all L1 test trials for the two aims
test_statues_trials = data(data.teststage == 4 & data.Level_type == 1 & strcmp(data.animal, STATUES_TRIAL_TARGET), :);
test_north_trials = data(data.teststage == 4 & data.Level_type == 1 & strcmp(data.animal, NORTH_TRIAL_TARGET), :);

% --- Combine into an intermediate table ---
intermediate_table = [training_statues_trials; training_north_trials; test_statues_trials; test_north_trials];
intermediate_table = sortrows(intermediate_table, {'subject', 'teststage', 'trial'});

fprintf('Intermediate table created with %d relevant trials.\n\n', height(intermediate_table));

%% --- 3. Calculate Per-Subject Change Scores ---
fprintf('Calculating change scores for each subject...\n');

subjects = unique(data.subject);
num_subjects = numel(subjects);
results = []; % Initialize empty struct array

measures = {'errors', 'abs_angle_error', 'path_efficiency', 'speed'};

for i = 1:num_subjects
    subj_id = subjects{i};
    subj_data = intermediate_table(strcmp(intermediate_table.subject, subj_id), :);
    
    current_result.Subject = subj_id;
    current_result.Group = subj_data.group(1);
    
    % --- Process STATUES condition ---
    train_st = subj_data(subj_data.teststage < 4 & strcmp(subj_data.animal, STATUES_TRIAL_TARGET), :);
    test_st = subj_data(subj_data.teststage == 4 & strcmp(subj_data.animal, STATUES_TRIAL_TARGET), :);
    
    if height(train_st) >= 2 && ~isempty(test_st)
        baseline = train_st(end-1:end, :); % Last 2 training trials
        test_trial = test_st(1, :);       % First test trial
        
        for m = 1:numel(measures)
            measure = measures{m};
            train_val = mean(baseline.(measure), 'omitnan');
            test_val = test_trial.(measure);
            
            current_result.(['Train_Statues_' measure]) = train_val;
            current_result.(['Test_Statues_' measure]) = test_val;
            current_result.(['Change_Statues_' measure]) = test_val - train_val;
        end
    else
        for m = 1:numel(measures) % Fill with NaNs if data is missing
            measure = measures{m};
            current_result.(['Train_Statues_' measure]) = NaN;
            current_result.(['Test_Statues_' measure]) = NaN;
            current_result.(['Change_Statues_' measure]) = NaN;
        end
    end
    
    % --- Process NORTH condition ---
    train_nt = subj_data(subj_data.teststage < 4 & strcmp(subj_data.animal, NORTH_TRIAL_TARGET), :);
    test_nt = subj_data(subj_data.teststage == 4 & strcmp(subj_data.animal, NORTH_TRIAL_TARGET), :);
    
    if height(train_nt) >= 2 && ~isempty(test_nt)
        baseline = train_nt(end-1:end, :); % Last 2 training trials
        test_trial = test_nt(1, :);       % First (and only) test trial
        
        for m = 1:numel(measures)
            measure = measures{m};
            train_val = mean(baseline.(measure), 'omitnan');
            test_val = test_trial.(measure);
            
            current_result.(['Train_North_' measure]) = train_val;
            current_result.(['Test_North_' measure]) = test_val;
            current_result.(['Change_North_' measure]) = test_val - train_val;
        end
    else
        for m = 1:numel(measures) % Fill with NaNs if data is missing
            measure = measures{m};
            current_result.(['Train_North_' measure]) = NaN;
            current_result.(['Test_North_' measure]) = NaN;
            current_result.(['Change_North_' measure]) = NaN;
        end
    end
    
    results = [results; current_result];
end

change_summary_table = struct2table(results);

% --- Save summary tables ---
writetable(intermediate_table, fullfile(output_directory, 'memory_change_intermediate_trials.xlsx'));
writetable(change_summary_table, fullfile(output_directory, 'memory_change_summary.xlsx'));
save(fullfile(output_directory, 'memory_change_summary.mat'), 'change_summary_table');
fprintf('Summary tables saved to output directory.\n\n');

%% --- 4. Generate Plots ---
fprintf('Generating memory change plots...\n');
group_colors = [0.2157, 0.4941, 0.7216; 0.8941, 0.1020, 0.1098]; % awake (blue), sleep (red)
group_names = unique(change_summary_table.Group);

if plot_type==0
    fprintf('Generating per subject memory change plots...\n');
    for p = 1:numel(measures)
        measure = measures{p};
        fig = figure('Position', [100, 100, 1200, 600]);
        
        conditions = {'Statues', 'North'};
        for s = 1:2
            subplot(1, 2, s);
            hold on;
            
            condition = conditions{s};
            title(condition, 'FontSize', 14);
            
            train_col = ['Train_' condition '_' measure];
            test_col = ['Test_' condition '_' measure];
            
            % Plot lines connecting training to test for each subject
            for i = 1:height(change_summary_table)
                group_idx = find(group_names == change_summary_table.Group(i));
                
                % Add small jitter to x-positions
                x1 = 1 + (rand-0.5)*0.2;
                x2 = 2 + (rand-0.5)*0.2;
                
                plot([x1, x2], [change_summary_table.(train_col)(i), change_summary_table.(test_col)(i)], ...
                    '-o', 'Color', [group_colors(group_idx,:), 0.5], 'LineWidth', 1, ...
                    'MarkerFaceColor', group_colors(group_idx,:), 'MarkerSize', 5);
            end
            
            all_vals = [change_summary_table.(train_col); change_summary_table.(test_col)];
            y_max_val = max(all_vals, [], 'omitnan') * 1.1;
            if isnan(y_max_val) || y_max_val == 0, y_max_val = 1; end
            ylim([0, y_max_val]);
            
            hold off;
            xlim([0.5, 2.5]);
            set(gca, 'XTick', [1, 2], 'XTickLabel', {'Training (Last 2 trials)', 'Test (First trial)'});
            ylabel(measure, 'Interpreter', 'none');
            
            if s == 1
                legend_handles = [];
                for g = 1:numel(group_names)
                    % Use dummy 'patch' objects to create robust legend handles
                    legend_handles(g) = patch(NaN, NaN, group_colors(g,:));
                end
                legend(legend_handles, cellstr(group_names), 'Location', 'northeast');
            end
            
            % Save figure
            figure_filename = fullfile(output_directory, ['test_training_plot_' measure '.png']);
            print(fig, figure_filename, '-dpng', '-r300');
            fprintf('  - Saved figure to %s\n', figure_filename);
        end
    end
else
    % Generate Group Comparison Plots of Change Scores
    fprintf('\nGenerating group comparison plots for change scores...\n');
    
    for p = 1:numel(measures)
        measure = measures{p};
        fig = figure('Position', [100, 100, 1200, 600]);
        
        conditions = {'Statues', 'North'};
        for s = 1:2
            subplot(1, 2, s);
            hold on;
            
            condition = conditions{s};
            title(condition, 'FontSize', 14);
            
            change_col = ['Change_' condition '_' measure];
            
            x_limits = [0.5, numel(group_names) + 0.5];
            % Add a horizontal line at y=0
            plot(x_limits, [0 0], '--', 'Color', [0.5 0.5 0.5]);
            
            for g = 1:numel(group_names)
                current_group = group_names(g);
                group_idx = g;
                x_pos = g; % Position groups at 1 and 2 on x-axis
                
                % Filter data for the current group
                group_data = change_summary_table(change_summary_table.Group == current_group, :);
                change_scores = group_data.(change_col);
                
                % --- Plot individual data points with jitter ---
                num_points = numel(change_scores);
                jitter = (rand(num_points, 1) - 0.5) * 0.2;
                plot(x_pos + jitter, change_scores, 'o', ...
                    'Color', group_colors(group_idx, :), ...
                    'MarkerFaceColor', group_colors(group_idx, :), ...
                    'MarkerEdgeColor', 'none', 'MarkerSize', 5);
                
                % --- Calculate and plot Mean +/- SEM ---
                mean_change = mean(change_scores, 'omitnan');
                sem_change = std(change_scores, 'omitnan') / sqrt(sum(~isnan(change_scores)));
                
                
                errorbar(x_pos, mean_change, sem_change, 'o', ...
                    'Color', group_colors(group_idx, :), ...
                    'MarkerFaceColor', group_colors(group_idx, :), ...
                    'MarkerSize', 8, 'LineWidth', 2, 'CapSize', 15);
            end
            
            hold off;
            xlim([0.5, numel(group_names) + 0.5]);
            set(gca, 'XTick', 1:numel(group_names), 'XTickLabel', cellstr(group_names));
            ylabel(['Change Test-Training (' measure ')'], 'Interpreter', 'none');
        end
        
        % Save figure
        figure_filename = fullfile(output_directory, ['memory_change_group_plot_' measure '.png']);
        print(fig, figure_filename, '-dpng', '-r300');
        fprintf('  - Saved figure to %s\n', figure_filename);
    end
    
    fprintf('All plots generated and saved.\n');
end
%% --- 4. Perform and Save Statistical Analysis ---
if do_stats
    fprintf('Performing statistical analysis on change scores...\n');
    
    % Prepare the table for statistical results
    stats_header = {'measure', 'U_statistic', 'p_value', 'n_Awake', 'median_Awake', 'iqr_Awake', 'n_Sleep', 'median_Sleep', 'iqr_Sleep'};
    stats_results = {};
    
    conditions = {'Statues', 'North'};
    
    for p = 1:numel(measures)
        measure = measures{p};
        for s = 1:numel(conditions)
            condition = conditions{s};
            
            change_col = ['Change_' condition '_' measure];
            
            % Extract data for each group and remove NaNs
            awake_data = change_summary_table.(change_col)(change_summary_table.Group == 'awake');
            awake_data = awake_data(~isnan(awake_data));
            
            sleep_data = change_summary_table.(change_col)(change_summary_table.Group == 'sleep');
            sleep_data = sleep_data(~isnan(sleep_data));
            
            % --- Perform Mann-Whitney U test ---
            p_val = NaN;
            u_stat = NaN;
            if ~isempty(awake_data) && ~isempty(sleep_data)
                [p_val_temp, ~, stats] = ranksum(awake_data, sleep_data);
                p_val = p_val_temp;
                u_stat = stats.ranksum;
            end
            
            % --- Calculate descriptive statistics ---
            n_awake = numel(awake_data);
            median_awake = median(awake_data);
            iqr_awake = iqr(awake_data);
            
            n_sleep = numel(sleep_data);
            median_sleep = median(sleep_data);
            iqr_sleep = iqr(sleep_data);
            
            % --- Assemble the new row for the stats table ---
            measure_name = [measure '_' condition];
            new_row = {measure_name, u_stat, p_val, n_awake, median_awake, iqr_awake, n_sleep, median_sleep, iqr_sleep};
            stats_results = [stats_results; new_row];
        end
    end
    
    % Convert to a table and save
    stats_table = cell2table(stats_results, 'VariableNames', stats_header);
    disp('Statistical Test Results (Mann-Whitney U):');
    disp(stats_table);
    
    output_xlsx = fullfile(output_directory, 'memory_change_summary.xlsx');
    writetable(stats_table, output_xlsx, 'Sheet', 'Statistics');
    fprintf('Statistical results saved as a new sheet in %s\n', output_xlsx);
end
end