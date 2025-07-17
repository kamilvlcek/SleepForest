function [subject_means, group_stats] = analyze_and_plot_results(data_filepath, output_directory, analysis_phase, plot_type, save_files)
% =========================================================================
%   This function loads a processed data table, makes summary across subjects and groups, 
%   and generates plots to compare experimental groups
%
%   INPUTS:
%       data_filepath (string):
%           Full path to the .mat file containing the data table from all subjects with groups
%
%       output_directory (string):
%           Full path to the folder where output files will be saved
%
%       analysis_phase (string):
%           Specifies which phase to analyze. Must be 'test' or 'training'
%
%       plot_type (string):
%           Specifies the type of plot. Must be 'mean_sem' (mean+-sem with individual data points)
%               or 'boxplot' (a classical boxplot with median, quartiles and outliers)
%
%       save_files (logical):
%           0/1 to indicate whether to save output tables and figures
%
%   OUTPUTS:
%       subject_means (table):
%           A table of per-subject means for the specified phase, saved to .mat and .xls files if save_files=1
%
%       group_stats (table):
%           A table of group-level statistics for the specified phase
%           
%      and all figures in png format if save_files=1
%
%   Example Usage:
%       data_file = 'E:\work\Sleep project\sleepforest\processed_spanav_results\all_subjects_data_with_groups.mat';
%       out_dir   = 'E:\work\Sleep project\sleepforest\processed_spanav_results';
%
%       % Run analysis for TEST phase with boxplots and save files
%       [test_subj, test_group] = analyze_and_plot_results(data_file, out_dir, 'test', 'boxplot', 1);
%
%       % Run analysis for TRAINING phase and display plots without saving
%       [train_subj, train_group] = analyze_and_plot_results(data_file, out_dir, 'training', 'mean_sem', 0);
% =========================================================================

    close all;

% --- 1. Configuration & Data Loading ---
    if save_files && ~exist(output_directory, 'dir')
        mkdir(output_directory);
    end
    
    % Load the data
    if ~exist(data_filepath, 'file')
        error('Input data file not found: %s', data_filepath);
    end
    fprintf('Loading data from: %s\n', data_filepath);
    load(data_filepath, 'final_table');  

% --- 2. Data Pre-processing ---
    fprintf('Pre-processing data...\n');

    % Calculate speed
    final_table.speed = final_table.length ./ final_table.duration ;
    % Handle potential division by zero if length is 0
    final_table.speed(isinf(final_table.speed) | isnan(final_table.speed)) = NaN;

    % Absolute angle error 
    final_table.abs_angle_error = abs(final_table.angle_error);

    % Create a more descriptive categorical variable for the cue condition
    final_table.CueCondition = categorical(repmat({''}, height(final_table), 1));
    final_table.CueCondition(final_table.North_marked == 1 & final_table.Statues_present == 0) = 'North';
    final_table.CueCondition(final_table.North_marked == 0 & final_table.Statues_present == 1) = 'Statues';
    final_table.group = categorical(final_table.group);

    fprintf('Data pre-processing complete.\n\n');

% --- 3. Analysis based on Phase ---
    if strcmpi(analysis_phase, 'test')
        fprintf('--- STARTING TEST PHASE ANALYSIS ---\n');
        data_to_analyze = final_table(final_table.teststage == 4 & ~isundefined(final_table.CueCondition) & ~isundefined(final_table.group), :);
        grouping_vars = {'subject', 'group', 'Level_type', 'CueCondition'};
        
    elseif strcmpi(analysis_phase, 'training')
        fprintf('--- STARTING TRAINING PHASE ANALYSIS ---\n');
        data_to_analyze = final_table(final_table.teststage < 4 & ~isundefined(final_table.group), :);
        grouping_vars = {'subject', 'group'};
        
    else
        error("Invalid 'analysis_phase' specified. Must be 'test' or 'training'.");
    end

    fprintf('%s PHASE: Calculating mean performance for each subject...\n', upper(analysis_phase));
    measures_to_summarize = {'errors', 'abs_angle_error', 'path_efficiency', 'speed'};
    subject_means = groupsummary(data_to_analyze, grouping_vars, 'mean', measures_to_summarize);

    if save_files
        fprintf('%s PHASE: Saving per-subject means table...\n', upper(analysis_phase));
        means_xlsx = fullfile(output_directory, [analysis_phase '_subject_means.xlsx']);
        means_mat  = fullfile(output_directory, [analysis_phase '_subject_means.mat']);
        writetable(subject_means, means_xlsx);
        save(means_mat, 'subject_means');
        fprintf('  - Saved to %s and .mat\n\n', means_xlsx);
    end

    % Calculating group-level summary with mean and sem
    vars_from_subject_means = strcat('mean_', measures_to_summarize);
    grouping_vars_for_plot = setdiff(grouping_vars, 'subject', 'stable');
    group_stats = groupsummary(subject_means, grouping_vars_for_plot, {'mean', 'std'}, vars_from_subject_means);
    
    for i = 1:length(measures_to_summarize)
        original_measure = measures_to_summarize{i};
        std_of_mean_col  = ['std_mean_'  original_measure];
        sem_col_name = ['sem_' original_measure];
        group_stats.(sem_col_name) = group_stats.(std_of_mean_col) ./ sqrt(group_stats.GroupCount); % SEM
    end

% --- 4. Plotting ---
    fprintf('%s PHASE: Plotting group-level results (%s)...\n', upper(analysis_phase), plot_type);
    measures_to_plot = {'errors', 'abs_angle_error', 'path_efficiency', 'speed'};
    plot_titles = {'Mean Number of Errors', 'Mean Absolute Angle Error', 'Mean Path Efficiency', 'Mean Speed'};
    y_labels = {'Mean Errors', 'Mean Abs Angle Error', 'Path Efficiency', 'Speed'};
    group_colors = [0.2157, 0.4941, 0.7216; 0.8941, 0.1020, 0.1098];
    group_names = unique(group_stats.group);
    
    if numel(group_names) < 2; warning('Fewer than two groups found for plotting.'); end
    group_names = sort(group_names);
    
    for p = 1:length(measures_to_plot)
        current_measure = measures_to_plot{p};
        
        if strcmpi(analysis_phase, 'test')
            fig = figure('Position', [100, 100, 1500, 600], 'Visible', 'on');
            if strcmpi(plot_type, 'mean_sem')
                plot_test_mean_sem(subject_means, group_stats, current_measure, group_names, group_colors, y_labels{p});
            elseif strcmpi(plot_type, 'boxplot')
                plot_test_boxplot(subject_means, current_measure, group_names, group_colors, y_labels{p});
            else
                error("Invalid 'plot_type' specified. Must be 'mean_sem' or 'boxplot'.");
            end
            
        elseif strcmpi(analysis_phase, 'training')
            fig = figure('Position', [100, 100, 600, 500], 'Visible', 'on');
            title(['Training Phase: ' plot_titles{p}], 'FontSize', 16, 'FontWeight', 'bold');

            if strcmpi(plot_type, 'mean_sem')
                plot_training_mean_sem(subject_means, group_stats, current_measure, group_names, group_colors, y_labels{p});
            elseif strcmpi(plot_type, 'boxplot')
                plot_training_boxplot(subject_means, current_measure, group_names, group_colors, y_labels{p});
            else
                 error("Invalid 'plot_type' specified. Must be 'mean_sem' or 'boxplot'.");
            end
        end
        
        if save_files
            figure_title_for_save = strrep(plot_titles{p}, ' ', '_');
            filename = sprintf('%s_plot_%s_%s.png', analysis_phase, plot_type, lower(figure_title_for_save));
            figure_filename = fullfile(output_directory, filename);
            print(fig, figure_filename, '-dpng', '-r300');
            fprintf('  - Saved figure to %s\n', figure_filename);
        end
    end
    
    fprintf('%s PHASE: Analysis complete.\n\n', upper(analysis_phase));

end

%% --- HELPER PLOTTING FUNCTIONS ---
function plot_test_mean_sem(subject_means, group_stats, measure, group_names, group_colors, y_label)
    mean_col = ['mean_mean_' measure]; sem_col = ['sem_' measure]; individual_col = ['mean_' measure]; 
    all_individual_data = subject_means.(individual_col);
    y_min = min(all_individual_data, [], 'omitnan'); y_max = max(all_individual_data, [], 'omitnan');
    if y_min == 0; y_min = -0.1 * y_max; end
    if isnan(y_min) || isnan(y_max) || y_min == y_max; y_min=0; y_max=1; end
    cue_conditions = {'Statues', 'North'};
    for s = 1:length(cue_conditions)
        subplot(1, 2, s); hold on; current_cue = cue_conditions{s}; legend_handles = [];
        for g = 1:numel(group_names)
            current_group = group_names(g);
            stats_subset = group_stats(group_stats.CueCondition == current_cue & group_stats.group == current_group, :);
            x_offset = -0.1 + (g-1)*0.2; x_positions = unique(stats_subset.Level_type)' + x_offset;
            if ~isempty(stats_subset); h = errorbar(x_positions, stats_subset.(mean_col), stats_subset.(sem_col), 'o', 'Color', group_colors(g, :), 'MarkerFaceColor', group_colors(g, :), 'MarkerSize', 6, 'LineWidth', 1.5, 'CapSize', 10); legend_handles(g) = h; end
            individual_subset = subject_means(subject_means.CueCondition == current_cue & subject_means.group == current_group, :);
            for lvl = 1:3
                level_data = individual_subset(individual_subset.Level_type == lvl, :);
                if ~isempty(level_data); num_points = height(level_data); x_base = lvl + x_offset; jitter = (rand(num_points, 1) - 0.5) * 0.08; plot(x_base + jitter, level_data.(individual_col), 'o', 'Color', group_colors(g, :), 'MarkerFaceColor', group_colors(g, :), 'MarkerEdgeColor', 'none', 'MarkerSize', 3); end
            end
        end
        hold off; title(current_cue, 'FontSize', 16); ylabel(y_label, 'FontSize', 14); set(gca, 'XTick', [1, 2, 3], 'XTickLabel', {'L1', 'L2', 'L3'}, 'FontSize', 12); xlim([0.5, 3.5]); ylim([y_min, y_max*1.1]); 
        if s == 1; legend(legend_handles, cellstr(group_names), 'Location', 'northeast', 'FontSize', 12); end
    end
end

function plot_test_boxplot(subject_means, measure, group_names, group_colors, y_label)
    individual_col = ['mean_' measure];
    all_individual_data = subject_means.(individual_col);
    y_min = min(all_individual_data, [], 'omitnan'); y_max = max(all_individual_data, [], 'omitnan');
    if isnan(y_min) || isnan(y_max) || y_min == y_max; y_min=0; y_max=1; end
    cue_conditions = {'Statues', 'North'};
    for s = 1:length(cue_conditions)
        ax = subplot(1, 2, s); hold on; current_cue = cue_conditions{s}; title(current_cue, 'FontSize', 14);
        data_for_subplot = subject_means(subject_means.CueCondition == current_cue, :);
        if isempty(data_for_subplot); ylabel(y_label, 'FontSize', 12); set(ax, 'XTick', [1.5, 4.5, 7], 'XTickLabel', {'L1', 'L2', 'L3'}, 'FontSize', 10); xlim([0, 8]); ylim([y_min, y_max*1.1]); text(mean(xlim), mean(ylim), 'No Data', 'FontSize', 14, 'HorizontalAlignment', 'center'); hold off; continue; end
        boxplot_grouping = {data_for_subplot.Level_type, data_for_subplot.group};
        h_boxplot = boxplot(data_for_subplot.(individual_col), boxplot_grouping, 'Colors', group_colors, 'Symbol', 'o', 'FactorGap', 10, 'Widths', 0.4);         
        set(h_boxplot, 'LineWidth', 1.5); medians = findobj(h_boxplot, 'Tag', 'Median'); set(medians, 'LineWidth', 2);
        hold off; ylabel(y_label, 'FontSize', 12); set(ax, 'XTick', [1.5, 4, 6.5], 'XTickLabel', {'L1', 'L2', 'L3'}, 'FontSize', 12); xlim([0, 7.5]); ylim([y_min, y_max*1.1]); 
        if s == 1; legend_handles = []; for g = 1:numel(group_names); legend_handles(g) = patch(NaN, NaN, group_colors(g,:)); end; legend(legend_handles, cellstr(group_names), 'Location', 'northeast', 'FontSize', 12); end
    end
end

function plot_training_mean_sem(subject_means, group_stats, measure, group_names, group_colors, y_label)
    mean_col = ['mean_mean_' measure]; sem_col = ['sem_' measure]; individual_col = ['mean_' measure]; 
    hold on;
    for g = 1:numel(group_names)
        current_group = group_names(g);
        stats_subset = group_stats(group_stats.group == current_group, :);
        x_position = g;
        if ~isempty(stats_subset); errorbar(x_position, stats_subset.(mean_col), stats_subset.(sem_col), 'o', 'Color', group_colors(g, :), 'MarkerFaceColor', group_colors(g, :), 'MarkerSize', 8, 'LineWidth', 2, 'CapSize', 15); end
        individual_subset = subject_means(subject_means.group == current_group, :);
        if ~isempty(individual_subset); num_points = height(individual_subset); jitter = (rand(num_points, 1) - 0.5) * 0.2; plot(x_position + jitter, individual_subset.(individual_col), 'o', 'Color', group_colors(g, :), 'MarkerFaceColor', group_colors(g, :), 'MarkerEdgeColor', 'none', 'MarkerSize', 5); end
    end
    hold off; ylabel(y_label, 'FontSize', 12); set(gca, 'XTick', [1, 2], 'XTickLabel', cellstr(group_names), 'FontSize', 12); xlim([0.5, 2.5]); 
end

function plot_training_boxplot(subject_means, measure, group_names, group_colors, y_label)
    individual_col = ['mean_' measure];
    hold on;
    h_boxplot = boxplot(subject_means.(individual_col), subject_means.group, ...
        'Colors', group_colors, ...
        'Symbol', 'o', ...
        'Widths', 0.5);
    
    set(h_boxplot, 'LineWidth', 1.5);
    medians = findobj(h_boxplot, 'Tag', 'Median');
    set(medians, 'LineWidth', 2);
    
    hold off;
    ylabel(y_label, 'FontSize', 12);
    set(gca, 'XTick', 1:numel(group_names), 'XTickLabel', cellstr(group_names), 'FontSize', 12);
    xlim([0.5, numel(group_names) + 0.5]);
    
    legend_handles = [];
    for g = 1:numel(group_names)
        legend_handles(g) = patch(NaN, NaN, group_colors(g,:));
    end
    legend(legend_handles, cellstr(group_names), 'Location', 'northeast', 'FontSize', 12);
end