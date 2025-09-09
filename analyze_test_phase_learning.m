function analyze_test_phase_learning(data_filepath, output_directory)
% Visualizes performance changes within the test phase.
%
%   This function analyzes if learning or performance changes occur across
%   trials within each specific test condition (Cue x Difficulty)
%   (simply, if participants get better or worse at the navigation
%   task during the test itself, and whether this pattern is different for the 'sleep' and 'awake' groups)
%
%   SYNTAX:
%       analyze_test_phase_learning(data_filepath, output_directory)
%
%   DESCRIPTION:
%       1. Loads the final data table containing all trials from all subjects.
%       2. Filters for test phase data only.
%       3. For each subject, it re-numbers trials based on their chronological
%          order within each unique condition (e.g., the 1st, 2nd, 3rd
%          'Statues Level 1' trial).
%       4. It calculates the group-level mean and SEM for each of these
%          within-condition trial numbers.
%       5. It generates and saves one figure for each of the five key
%          performance measures. Each figure contains two subplots (Statues
%          and North), showing the performance trend across trials for each
%          difficulty level.
%
%   Example Usage:
%       data_file = 'E:\results\all_subjects_data_with_groups.mat';
%       out_dir   = 'E:\results\test_learning_analysis';
%       analyze_test_phase_learning(data_file, out_dir);

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

    if ~ismember('CueCondition', final_table.Properties.VariableNames)
        final_table.CueCondition = categorical(repmat({''}, height(final_table), 1));
        final_table.CueCondition(final_table.North_marked == 1 & final_table.Statues_present == 0) = 'North';
        final_table.CueCondition(final_table.North_marked == 0 & final_table.Statues_present == 1) = 'Statues';
    end

    test_data = final_table(final_table.teststage == 4 & ~isundefined(final_table.CueCondition) & ~isundefined(final_table.group), :);
    
    %% --- 3. De-duplicate and Renumber Trials ---
    % If a participant failed a trial and had to immediately repeat it, the function keeps only the first attempt
    fprintf('De-duplicating repeated test trials by checking for immediate repeats within the same full condition...\n');
    
    subjects = unique(test_data.subject);
    test_data_deduplicated = []; % Initialize an empty table for the cleaned data
    
    for i = 1:numel(subjects)
        subj_id = subjects{i};
        
        % Get and sort this subject's data chronologically
        subject_data = test_data(strcmp(test_data.subject, subj_id), :);
        subject_data = sortrows(subject_data, 'trial');
        
        rows_to_keep = true(height(subject_data), 1);
        
        % Iterate from the second trial onwards to compare with the previous one
        for k = 2:height(subject_data)
            % A trial is a duplicate ONLY IF the animal, level, AND cue condition are all the same as the previous trial
            is_same_animal = strcmp(subject_data.animal{k}, subject_data.animal{k-1});
            is_same_level = subject_data.Level_type(k) == subject_data.Level_type(k-1);
            is_same_cue = subject_data.CueCondition(k) == subject_data.CueCondition(k-1);
            
            if is_same_animal && is_same_level && is_same_cue
                rows_to_keep(k) = false; % Mark this duplicate for removal
            end
        end
        
        test_data_deduplicated = [test_data_deduplicated; subject_data(rows_to_keep, :)];
    end
    
    test_data = test_data_deduplicated;
    
    fprintf('De-duplication complete. %d unique trials remain.\n', height(test_data));
    
    fprintf('Numbering trials within each condition for each subject...\n');
    
    cue_conditions = {'Statues', 'North'};
    levels = [1, 2, 3];
    
    test_data_renumbered = [];
    
    for i = 1:numel(subjects)
        subj_id = subjects{i};
        subject_data = test_data(strcmp(test_data.subject, subj_id), :);
        for s = 1:numel(cue_conditions)
            current_cue = cue_conditions{s};
            for l = 1:numel(levels)
                current_level = levels(l);
                condition_trials = subject_data(subject_data.CueCondition == current_cue & subject_data.Level_type == current_level, :);
                if ~isempty(condition_trials)
                    condition_trials = sortrows(condition_trials, 'trial');
                    condition_trials.ConditionTrialNum = (1:height(condition_trials))';
                    test_data_renumbered = [test_data_renumbered; condition_trials];
                end
            end
        end
    end
    
    fprintf('Renumbering complete.\n\n');
    
    %% --- 4. Calculate Group-Level Statistics ---
    fprintf('Calculating group-level statistics for each condition trial...\n');
    
    measures_to_summarize = {'aim_found', 'errors', 'abs_angle_error', 'path_efficiency', 'speed'};
    grouping_vars = {'group', 'CueCondition', 'Level_type', 'ConditionTrialNum'};
    
    summary_table = groupsummary(test_data_renumbered, grouping_vars, {'mean', 'std', 'numel'}, measures_to_summarize);
    
    for m = 1:numel(measures_to_summarize)
        measure = measures_to_summarize{m};
        summary_table.(['sem_' measure]) = summary_table.(['std_' measure]) ./ sqrt(summary_table.GroupCount);
    end

    disp('Summary table for plotting:');
    disp(summary_table);
    
    %% --- 5. Generate Plots ---
    fprintf('Generating learning curves during the test...\n');
    
    plot_measures = {'mean_aim_found', 'mean_errors', 'mean_abs_angle_error', 'mean_path_efficiency', 'mean_speed'};
    plot_sem_vars = {'sem_aim_found', 'sem_errors', 'sem_abs_angle_error', 'sem_path_efficiency', 'sem_speed'};
    plot_titles = {'Success Rate', 'Number of Errors', 'Absolute Angle Error', 'Path Efficiency', 'Speed'};
    y_labels = {'Success Rate (Proportion)', 'Mean Errors', 'Mean Abs Angle Error', 'Mean Path Efficiency', 'Mean Speed'};
    level_colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250]; % Blue, Red, Yellow for L1, L2, L3
    
    group_names = unique(summary_table.group);
    group_names = sort(group_names); % Ensure consistent order (awake, sleep)
    
    % Define line styles for each group 
    line_styles = {'-', '--'}; % Solid for awake, dashed for sleep
    
    for p = 1:length(plot_measures)
        current_measure = plot_measures{p};
        current_sem = plot_sem_vars{p};
        
        fig = figure('Position', [100, 100, 1200, 600]);
        
        for s = 1:numel(cue_conditions)
            ax = subplot(1, 2, s);
            hold on;
            current_cue = cue_conditions{s};
            title(current_cue, 'FontSize', 14);
            
            legend_handles = [];
            legend_names = {};
            
            for l = 1:numel(levels)
                current_level = levels(l);
                
                for g = 1:numel(group_names)
                    current_group = group_names(g);
                    
                    % Filter summary data for this group, cue, and level
                    data_to_plot = summary_table(summary_table.group == current_group & ...
                                                 summary_table.CueCondition == current_cue & ...
                                                 summary_table.Level_type == current_level, :);
                    
                    if ~isempty(data_to_plot)
                        x_vals = data_to_plot.ConditionTrialNum;
                        y_vals = data_to_plot.(current_measure);
                        sem_vals = data_to_plot.(current_sem);
                        
                        % Plot the line with group-specific style and level-specific color
                        h = plot(x_vals, y_vals, 'o-', ...
                            'LineStyle', line_styles{g}, ...
                            'Color', level_colors(l,:), ...
                            'LineWidth', 2, 'MarkerFaceColor', 'w');
                        
                        % Add to legend info
                        legend_handles(end+1) = h;
                        legend_names{end+1} = sprintf('%s - Level %d', current_group, current_level);
                        
                        % Plot the shaded error region
                        fill([x_vals; flipud(x_vals)], [y_vals-sem_vals; flipud(y_vals+sem_vals)], ...
                            level_colors(l,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
                    end
                end
            end
            
            hold off;
            grid on; box on;
            xlabel('Trial Number within Condition', 'FontSize', 12);
            ylabel(y_labels{p}, 'FontSize', 12);
            
            max_trials_in_table = max(summary_table.ConditionTrialNum);
            if ~isempty(max_trials_in_table) && max_trials_in_table > 0
                xlim([0.5, max_trials_in_table + 0.5]);
                set(ax, 'XTick', 1:max_trials_in_table);
            end

            if s == 1
                if ~isempty(legend_handles)
                    legend(legend_handles, legend_names, 'Location', 'best');
                end
            end
        end
        
        % Save the figure
        figure_title_for_save = strrep(plot_titles{p}, ' ', '_');
        figure_filename = fullfile(output_directory, ['test_learning_plot_by_group_' lower(figure_title_for_save) '.png']);
        print(fig, figure_filename, '-dpng', '-r300');
        fprintf('  - Saved figure to %s\n', figure_filename);
        
    output_xlsx = fullfile(output_directory, 'learning_test_summary.xlsx');
    writetable(summary_table, output_xlsx);
    end
    
    fprintf('Summary table saved as %s\n', output_xlsx);
    fprintf('All plots generated and saved.\n\n');

end