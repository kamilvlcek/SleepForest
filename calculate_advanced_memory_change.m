function [change_summary_table, stats_table] = calculate_advanced_memory_change(data_filepath, output_directory, do_stats)
% Calculates and visualizes memory change across all difficulty levels
%
%   This function calculates a normalized memory change score for each 
%   subject across all three difficulty levels (L1, L2, L3) by comparing
%   the first test trial of each type against a specific training baseline. 
%   It then visualizes the results and optionally 
%   performs statistical tests (Mann-Whitney test).
%
%   DESCRIPTION OF METHODOLOGY:
%       1. Loads the final data table containing all trials from all subjects.
%       2. Filters for subjects in the 'sleep' or 'awake' groups.
%       3. For each subject, it processes each combination of Cue Condition
%          (Statues, North) and Difficulty Level (L1, L2, L3).
%       4. It identifies the VERY FIRST test trial that matches the given
%          condition (e.g., the first L2 Statues trial).
%       5. It calculates a specific training baseline for that trial:
%          - L1 BASELINE: Performance on the LAST training trial of the 
%            exact same path (e.g., A->B).
%          - L2 BASELINE: The AVERAGE performance of the LAST training trials
%            of the two constituent L1 components (e.g., A->B and B->C for 
%            an A->C test trial).
%          - L3 BASELINE: The AVERAGE performance of the LAST training trials
%            of all unique L1 paths (8 pairs), serving as a global baseline.
%       6. It calculates a Change Score (Test Performance - Training Baseline)
%          for four key performance measures (errors, angle error, path
%          efficiency, speed).
%       7. It returns a final long-format summary table with one row per 
%          subject/condition/level/measure.
%       8. It generates plots showing the group comparison (Mean/SEM + 
%          individual points) for each difficulty level.
%
%   INPUTS:
%       data_filepath (string):
%           The full path to the .mat file of the final data table with 
%           group assignments (e.g., 'all_subjects_data_with_groups.mat').
%
%       output_directory (string):
%           The full path to the folder where output summary tables and 
%           figures will be saved.
%
%       do_stats (logical, 1 or 0):
%           If true (1), the function performs Mann-Whitney U tests on the
%           change scores between the sleep and awake groups for each
%           condition and saves the results.
%
%   OUTPUTS:
%       change_summary_table (table):
%           A long-format table containing the calculated change scores. Each
%           row represents a single subject's change score for a specific
%           measure, in a specific condition (Cue x Level). This table is
%           saved to 'memory_change_summary_L1_L2_L3_long.xlsx' and .mat.
%
%       stats_table (table):
%           A table summarizing the results of the Mann-Whitney U tests.
%           This is saved as a separate sheet in the summary Excel file.
%           Returns an empty table if do_stats is false.
%
%   Example Usage:
%       data_file = 'E:\results\all_subjects_data_with_groups.mat';
%       out_dir   = 'E:\results\advanced_memory_change';
%       [summary, stats] = calculate_advanced_memory_change(data_file, out_dir, true);

    close all;

    %% --- 1. Configuration & Data Loading ---
    if ~exist(output_directory, 'dir'); mkdir(output_directory); end
    if ~exist(data_filepath, 'file'); error('Input data file not found: %s', data_filepath); end
    fprintf('Loading data from: %s\n', data_filepath);
    load(data_filepath, 'final_table');

    %% --- 2. Data Pre-processing & Path Definitions ---
    fprintf('Pre-processing and defining path structures...\n');
    
    % --- Pre-calculate measures ---
    final_table.speed = final_table.length ./ final_table.duration;
    final_table.speed(isinf(final_table.speed) | isnan(final_table.speed)) = NaN;
    final_table.abs_angle_error = abs(final_table.angle_error);
    final_table.group = categorical(final_table.group);
    if ~ismember('CueCondition', final_table.Properties.VariableNames)
        final_table.CueCondition = categorical(repmat({''}, height(final_table), 1));
        final_table.CueCondition(final_table.North_marked == 1 & final_table.Statues_present == 0) = 'North';
        final_table.CueCondition(final_table.North_marked == 0 & final_table.Statues_present == 1) = 'Statues';
    end
    
    % L2 Test Paths and their L1 training components
    l2_map = struct();
    l2_map.AC = [1 2; 2 3]; l2_map.CA = [1 2; 2 3];
    l2_map.DF = [4 5; 5 6]; l2_map.FD = [4 5; 5 6];
    l2_map.GI = [7 8; 8 9]; l2_map.IG = [7 8; 8 9];
    
    % All unique L1 pairs for L3 normalization
    all_l1_training_pairs = unique(sort([1 2; 2 3; 3 6; 6 5; 9 8; 8 7; 7 4; 5 4], 2), 'rows');
    
    % --- Filter for relevant data ---
    data = final_table(ismember(final_table.group, {'sleep', 'awake'}), :);
    subjects = unique(data.subject);
    measures = {'errors', 'abs_angle_error', 'path_efficiency', 'speed'};
    results = [];
    
    %% --- 3. Calculate Per-Subject Change Scores for L1, L2, L3 ---
    fprintf('Calculating change scores for each subject across all levels...\n');
    
    for i = 1:numel(subjects)
        subj_id = subjects{i};
        subj_data = data(strcmp(data.subject, subj_id), :);
        subj_training = subj_data(subj_data.teststage < 4, :);
        subj_test = subj_data(subj_data.teststage == 4, :);
        
        % Calculate the Global L3 Training Baseline for this subject once
        l3_global_baselines = struct();
        for m = 1:numel(measures)
            measure = measures{m};
            baselines_for_measure = [];
            for p = 1:size(all_l1_training_pairs, 1)
                baselines_for_measure = [baselines_for_measure; get_last_training_trial(subj_training, all_l1_training_pairs(p,:), measure)];
            end
            l3_global_baselines.(measure) = mean(baselines_for_measure, 'omitnan');
        end

        for cue_cond = ["Statues", "North"]
            for lvl = 1:3
                % --- Find the FIRST test trial for this condition ---
                test_trials_in_cond = subj_test(subj_test.CueCondition == cue_cond & subj_test.Level_type == lvl, :);
                if isempty(test_trials_in_cond)
                    continue; % Skip if no trials for this condition
                end
                test_trials_in_cond = sortrows(test_trials_in_cond, 'trial');
                first_test_trial = test_trials_in_cond(1, :);
                
                for m = 1:numel(measures)
                    measure = measures{m};
                    test_perf = first_test_trial.(measure);
                    train_baseline = NaN;
                    
                    % --- Calculate the appropriate Training Baseline ---
                    if lvl == 1
                        pair = [first_test_trial.StartField, first_test_trial.GoalField];
                        train_baseline = get_last_training_trial(subj_training, pair, measure);
                    elseif lvl == 2
                        path_name = [char(first_test_trial.StartField+'A'-1), char(first_test_trial.GoalField+'A'-1)];
                        if isfield(l2_map, path_name)
                            components = l2_map.(path_name);
                            comp1_perf = get_last_training_trial(subj_training, components(1,:), measure);
                            comp2_perf = get_last_training_trial(subj_training, components(2,:), measure);
                            train_baseline = mean([comp1_perf, comp2_perf], 'omitnan');
                        end
                    elseif lvl == 3
                        train_baseline = l3_global_baselines.(measure);
                    end
                    
                    % --- Store the results in a long format ---
                    new_row.Subject = subj_id;
                    new_row.Group = subj_data.group(1);
                    new_row.CueCondition = cue_cond;
                    new_row.Level = lvl;
                    new_row.Measure = string(measure);
                    new_row.ChangeScore = test_perf - train_baseline;
                    results = [results; new_row];
                end
            end
        end
    end

    change_summary_table = struct2table(results);
    disp('Final Long-Format Change Score Summary Table:');
    disp(head(change_summary_table));
    
    writetable(change_summary_table, fullfile(output_directory, 'memory_change_summary_L1_L2_L3_long.xlsx'));
    save(fullfile(output_directory, 'memory_change_summary_L1_L2_L3_long.mat'), 'change_summary_table');
    fprintf('Summary tables saved to output directory.\n\n');

    %% --- 4. Generate Plots ---
    fprintf('\nGenerating group comparison plots for change scores...\n');
    
    plot_titles = {'Change: Errors', 'Change: Abs. Angle Error', 'Change: Path Efficiency', 'Change: Speed'};
    group_colors = [0.2157, 0.4941, 0.7216; 0.8941, 0.1020, 0.1098]; % awake (blue), sleep (red)
    group_names = unique(change_summary_table.Group);
    
    for p = 1:numel(measures)
        measure_name = measures{p};
        
        % Create one figure for each difficulty level
        for lvl = 1:3
            fig = figure('Position', [100, 100, 1200, 600]);
            
            annotation('textbox', [0, 0.9, 1, 0.1], ...
            'String', sprintf('%s - Level %d', plot_titles{p}, lvl), ...
            'EdgeColor', 'none', ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 14, ...
            'FontWeight', 'bold');

            for s = 1:2
                ax = subplot(1, 2, s);
                hold on;
                
                cue_cond_name = ["Statues", "North"];
                current_cue = cue_cond_name(s);
                title(current_cue, 'FontSize', 14);
                
                legend_handles = [];
                for g = 1:numel(group_names)
                    current_group = group_names(g);
                    x_pos = g; % Groups at x=1 and x=2
                    
                    % Filter data for this specific plot
                    data_subset = change_summary_table(change_summary_table.Group == current_group & ...
                                                       change_summary_table.CueCondition == current_cue & ...
                                                       change_summary_table.Level == lvl & ...
                                                       change_summary_table.Measure == measure_name, :);
                    
                    if ~isempty(data_subset)
                        change_scores = data_subset.ChangeScore;
                        
                        % Plot individual points with jitter
                        jitter = (rand(size(change_scores)) - 0.5) * 0.2;
                        plot(x_pos + jitter, change_scores, 'o', 'Color', group_colors(g,:), 'MarkerFaceColor', group_colors(g,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 5);
                        
                        % Calculate and plot Mean +/- SEM
                        mean_change = mean(change_scores, 'omitnan');
                        sem_change = std(change_scores, 'omitnan') / sqrt(sum(~isnan(change_scores)));
                        
                        h = errorbar(x_pos, mean_change, sem_change, 'o', 'Color', group_colors(g,:), 'MarkerFaceColor', group_colors(g,:), 'MarkerSize', 8, 'LineWidth', 2, 'CapSize', 15);
                        legend_handles(g) = h;
                    end
                end

                set(gca, 'XTick', 1:numel(group_names), 'XTickLabel', cellstr(group_names));
                ylabel(['Change Test-Training (' measure_name ') L' num2str(lvl)], 'Interpreter', 'none');
                xlim([0.5, numel(group_names) + 0.5]);                                
                x_limits = get(gca, 'XLim'); % Get the current x-axis limits
                plot(x_limits, [0 0], '--', 'Color', [0.5 0.5 0.5]);
                hold off;
                grid off;
                
                if s == 1
                    if ~isempty(legend_handles); legend(legend_handles, cellstr(group_names), 'Location', 'best'); end
                end
            end
            
            % Save the figure
            figure_filename = fullfile(output_directory, sprintf('memory_change_L%d_plot_%s.png', lvl, measure_name));
            print(fig, figure_filename, '-dpng', '-r300');
            fprintf('  - Saved figure to %s\n', figure_filename);
        end
    end

    %% --- 5. Statistical Analysis ---
    stats_table = [];
    if do_stats
        fprintf('\nPerforming statistical analysis on change scores...\n');
        stats_header = {'measure', 'cue_condition', 'level', 'U_statistic', 'p_value', 'n_Awake', 'median_Awake', 'iqr_Awake', 'n_Sleep', 'median_Sleep', 'iqr_Sleep'};
        stats_results = {};
        
        for m = 1:numel(measures)
            measure_name = measures{m};
            for s = 1:2
                current_cue = cue_cond_name(s);
                for lvl = 1:3
                    data_subset = change_summary_table(change_summary_table.Measure == measure_name & ...
                                                       change_summary_table.CueCondition == current_cue & ...
                                                       change_summary_table.Level == lvl, :);
                                                       
                    awake_data = data_subset.ChangeScore(data_subset.Group == 'awake');
                    sleep_data = data_subset.ChangeScore(data_subset.Group == 'sleep');
                    
                    p_val = NaN; u_stat = NaN;
                    if ~isempty(awake_data) && ~isempty(sleep_data)
                        [p_val_temp, ~, stats] = ranksum(awake_data, sleep_data);
                        p_val = p_val_temp; u_stat = stats.ranksum;
                    end
                    
                    n_awake = sum(~isnan(awake_data)); median_awake = median(awake_data, 'omitnan'); iqr_awake = iqr(awake_data);
                    n_sleep = sum(~isnan(sleep_data)); median_sleep = median(sleep_data, 'omitnan'); iqr_sleep = iqr(sleep_data);
                    
                    new_row = {measure_name, char(current_cue), sprintf('L%d', lvl), u_stat, p_val, n_awake, median_awake, iqr_awake, n_sleep, median_sleep, iqr_sleep};
                    stats_results = [stats_results; new_row];
                end
            end
        end
        stats_table = cell2table(stats_results, 'VariableNames', stats_header);
        %disp(stats_table);
        writetable(stats_table, fullfile(output_directory, 'memory_change_summary_L1_L2_L3_long.xlsx'), 'Sheet', 'Statistics');
    end
end

% --- Helper function to get the LAST training trial for a specific pair ---
function baseline = get_last_training_trial(training_table, pair, measure)
    is_pair = (training_table.StartField == pair(1) & training_table.GoalField == pair(2)) | ...
              (training_table.StartField == pair(2) & training_table.GoalField == pair(1));
    pair_trials = training_table(is_pair, :);
    if ~isempty(pair_trials)
        pair_trials = sortrows(pair_trials, 'trial');
        baseline = pair_trials.(measure)(end);
    else
        baseline = NaN;
    end
end
