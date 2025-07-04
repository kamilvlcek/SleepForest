% summary and visualization across groups, levels, cue condition

clear;
clc;
close all;

%% --- 1. Configuration & Data Loading ---
% Directory where .mat file is located
data_directory = 'E:\work\Sleep project\sleepforest\processed_spanav_results';
input_filename = 'all_subjects_data_with_groups.mat';

% Load the data
input_filepath = fullfile(data_directory, input_filename);
if ~exist(input_filepath, 'file')
    error('Input data file not found: %s', input_filepath);
end
fprintf('Loading data from: %s\n', input_filepath);
load(input_filepath, 'final_table'); 

%% --- 2. Data Pre-processing ---
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

% Filter data for the analysis (test and training separately)
test_data = final_table(final_table.teststage == 4 & ~isundefined(final_table.CueCondition) & ~strcmp(final_table.group, ''), :); 
training_data = final_table(final_table.teststage < 4 & ~strcmp(final_table.group, ''), :);

test_data.group = categorical(test_data.group);

fprintf('Data pre-processing complete.\n\n');

%% --- TEST PHASE ANALYSIS ---
%% --- 3. Summarize Data per Subject ---
% mean for each subject in each condition
fprintf('TEST PHASE: Calculating mean performance for each subject...\n');

grouping_vars = {'subject', 'group', 'Level_type', 'CueCondition'};
measures_to_summarize = {'errors', 'abs_angle_error', 'path_efficiency', 'speed'};

% Use groupsummary to get the mean for each subject
subject_means_table = groupsummary(test_data, grouping_vars, 'mean', measures_to_summarize);

% save table
fprintf('TEST PHASE: Saving per-subject means table...\n');
test_means_xlsx_filename = fullfile(data_directory, 'test_subject_means.xlsx');
test_means_mat_filename  = fullfile(data_directory, 'test_subject_means.mat');
writetable(subject_means_table, test_means_xlsx_filename);
save(test_means_mat_filename, 'subject_means_table');
fprintf('  - Saved to %s and .mat\n\n', test_means_xlsx_filename);

%% --- 4. Calculate Group-Level Statistics (Mean & SEM) ---
fprintf('Calculating group-level statistics (Mean and SEM)...\n');

% These are the output columns from the previous step.
vars_from_subject_means = strcat('mean_', measures_to_summarize);

grouping_vars_for_plot = {'Level_type', 'CueCondition', 'group'};

% This will create columns like 'mean_mean_errors', 'std_mean_errors', etc.
group_stats_table = groupsummary(subject_means_table, grouping_vars_for_plot, {'mean', 'std'}, vars_from_subject_means);

% SEM = std / sqrt(n)
for i = 1:length(measures_to_summarize)
    original_measure = measures_to_summarize{i};
    
    % Construct the names that groupsummary created
    mean_of_mean_col = ['mean_mean_' original_measure];
    std_of_mean_col  = ['std_mean_'  original_measure];
    
    % Name for the new clean SEM column
    sem_col_name = ['sem_' original_measure];
    
    % Perform the calculation
    group_stats_table.(sem_col_name) = group_stats_table.(std_of_mean_col) ./ sqrt(group_stats_table.GroupCount);
end

disp('Final Group-Level Statistics for Plotting:');
disp(group_stats_table);

%% --- 5. Generate Plots ---
fprintf('Generating comparison plots...\n');

measures_to_plot = {'errors', 'abs_angle_error', 'path_efficiency', 'speed'};
plot_titles = {'Mean Number of Errors', 'Mean Absolute Angle Error', 'Mean Path Efficiency', 'Mean Speed'};
y_labels = {'Mean Errors', 'Mean Abs Angle Error', 'Path Efficiency', 'Speed'};

% Define colors for the groups 
group_colors = [0.2157, 0.4941, 0.7216;  % Blue for group 1 
                0.8941, 0.1020, 0.1098]; % Red for group 2 

% Get group names and ensure there are two
group_names = unique(group_stats_table.group);
if numel(group_names) ~= 2
    error('Expected exactly two groups for plotting (e.g., "sleep", "awake"). Found %d.', numel(group_names));
end
% sort them to ensure consistent color assignment
group_names = sort(group_names); % e.g., {'awake', 'sleep'}

% --- Main Plotting Loop ---
for p = 1:length(measures_to_plot)
    
    current_measure = measures_to_plot{p};
    
    % The column names for the mean and SEM data
    mean_col = ['mean_mean_' current_measure];
    sem_col = ['sem_' current_measure];
    individual_col = ['mean_' current_measure]; % From the subject_means_table
    
    % --- Create a new figure for each measure ---
    fig = figure('Position', [100, 100, 1500, 600], 'Visible', 'on');
    
    % Get overall Y-axis limits for consistent scaling across subplots
    all_individual_data = subject_means_table.(individual_col);
    y_min = min(all_individual_data) * 0.9;
    y_max = max(all_individual_data) * 1.1;

    % --- Loop to create the two subplots (Statues and North) ---
    cue_conditions = {'Statues', 'North'};
    for s = 1:length(cue_conditions)
        
        subplot(1, 2, s);
        hold on;
        
        current_cue = cue_conditions{s};
        
        % --- Loop through each group (awake, sleep) to plot them ---
        legend_handles = []; % To store handles for the legend
        
        for g = 1:numel(group_names)
            current_group = group_names(g);
            
            % --- Plot 1: Mean and SEM ---
            
            % Filter the stats table for the current cue and group
            stats_subset = group_stats_table(group_stats_table.CueCondition == current_cue & ...
                                             group_stats_table.group == current_group, :);
            
            % X-axis positions with "dodge"
            x_offset = -0.1 + (g-1)*0.2; % e.g., -0.1 for group 1, +0.1 for group 2
            x_positions = unique(stats_subset.Level_type)' + x_offset;
            
            if ~isempty(stats_subset)
                h = errorbar(x_positions, stats_subset.(mean_col), stats_subset.(sem_col), ...
                    'o', ... % Marker style
                    'Color', group_colors(g, :), ...
                    'MarkerFaceColor', group_colors(g, :), ...
                    'MarkerSize', 6, ...
                    'LineWidth', 1.5, ...
                    'CapSize', 10);
                legend_handles(g) = h;
            end
            
            % --- Plot 2: Individual Data Points with Jitter ---
            
            % Filter the individual subject means table
            individual_subset = subject_means_table(subject_means_table.CueCondition == current_cue & ...
                                                    subject_means_table.group == current_group, :);
                                                
            % Add jittered points for each difficulty level
            for lvl = 1:3
                level_data = individual_subset(individual_subset.Level_type == lvl, :);
                if ~isempty(level_data)
                    num_points = height(level_data);
                    x_base = lvl + x_offset;
                    % Add random jitter to x-coordinates
                    jitter = (rand(num_points, 1) - 0.5) * 0.08; % Controls jitter width
                    
                    plot(x_base + jitter, level_data.(individual_col), ...
                        'o', ...
                        'Color', group_colors(g, :), ...
                        'MarkerFaceColor', group_colors(g, :), ...
                        'MarkerEdgeColor', 'none', ...
                        'MarkerSize', 3);

                end
            end
        end
        
        % --- Customize the Subplot ---
        hold off;
        title(current_cue, 'FontSize', 16);
        ylabel(y_labels{p}, 'FontSize', 12);
        set(gca, 'XTick', [1, 2, 3], 'XTickLabel', {'L1', 'L2', 'L3'}, 'FontSize', 12);
        xlim([0.5, 3.5]);
        ylim([0, y_max]); % Apply consistent Y limits
        %box on;
        
        % Add legend only to the first subplot to avoid repetition
       if s == 1
             legend(legend_handles, cellstr(group_names), 'Location', 'northeast', 'FontSize', 12);
        end
    end
    
    figure_title_for_save = strrep(plot_titles{p}, ' ', '_');
    figure_filename = fullfile(data_directory, ['test_plot_mean_sem_' lower(figure_title_for_save) '.png']); 
    print(fig,figure_filename,'-dpng', '-r300');
    fprintf('  - Saved figure to %s\n', figure_filename);
end

fprintf('TEST PHASE: All plots generated.\n');

%% --- SECTION 5b - Generate Box Plots for TEST Data 
fprintf('TEST PHASE: Generating Box Plot comparison plots...\n');

for p = 1:length(measures_to_plot)
    
    current_measure = measures_to_plot{p};
    individual_col = ['mean_' current_measure]; % The data to plot is in the per-subject table
    
    fig = figure('Position', [100, 100, 1500, 600], 'Visible', 'on');
    
    all_individual_data = subject_means_table.(individual_col);
    y_min = min(all_individual_data, [], 'omitnan');
    y_max = max(all_individual_data, [], 'omitnan');
    if isnan(y_min) || isnan(y_max) || y_min == y_max; y_min=0; y_max=1; end
    
    cue_conditions = {'Statues', 'North'};
    for s = 1:length(cue_conditions)
        
        ax = subplot(1, 2, s);
        hold on;
        current_cue = cue_conditions{s};
        title(current_cue, 'FontSize', 16);
        
        % Filter data for the current subplot
        data_for_subplot = subject_means_table(subject_means_table.CueCondition == current_cue, :);
        
        % --- Robustness Check: Skip this subplot if there's no data ---
        if isempty(data_for_subplot)
            % Set labels and ticks for consistency, then continue
            ylabel(y_labels{p}, 'FontSize', 12);
            set(ax, 'XTick', [1.5, 4.5, 7], 'XTickLabel', {'L1', 'L2', 'L3'}, 'FontSize', 12);
            xlim([0.5, 8]);
            ylim([y_min, y_max*1.1]);
            text(mean(xlim), mean(ylim), 'No Data', 'FontSize', 14, 'HorizontalAlignment', 'center');
            hold off;
            continue; % Go to the next subplot
        end
        
        % --- Plot the Boxplots, grouped by level and group ---
        % The grouping variables must be in a cell array
        boxplot_grouping = {data_for_subplot.Level_type, data_for_subplot.group};
        
        boxplot(data_for_subplot.(individual_col), boxplot_grouping, ...
            'Colors', group_colors, ...
            'Symbol', 'o', ...      % Show outliers as circles
            'FactorGap', 14, ...    % Space between L1, L2, L3 groups
            'Widths', 0.5);         % Adjust width of boxes

        % --- Customize the Subplot ---
        % Find all parts of the boxplot in the current axes
        boxes = findobj(ax, 'Tag', 'Box');
        medians = findobj(ax, 'Tag', 'Median');
        whiskers = findobj(ax, 'Tag', 'Whisker');
        
        % Set a new line width for all these parts
        set(boxes, 'LineWidth', 1);
        set(medians, 'LineWidth', 1.5); 
        set(whiskers, 'LineWidth', 1);
        box off

        hold off;
        ylabel(y_labels{p}, 'FontSize', 12);
        
        % Customize x-axis to be more readable
        set(ax, 'XTick', [1.5, 4.1, 7], 'XTickLabel', {'L1', 'L2', 'L3'}, 'FontSize', 12);
        xlim([0, 8]);
        ylim([y_min, y_max*1.1]);
        
        % --- Create a manual legend for the groups ---
        if s == 1
            legend_handles = [];
            for g = 1:numel(group_names)
                % Plot invisible points to create legend entries
                legend_handles(g) = patch(NaN, NaN, group_colors(g,:));
            end
            legend(legend_handles, cellstr(group_names), 'Location', 'northeast', 'FontSize', 12);
        end
    end
    
    % --- Save the Box Plot Figure ---
    figure_title_for_save = strrep(plot_titles{p}, ' ', '_');
    figure_filename = fullfile(data_directory, ['test_plot_boxplot_' lower(figure_title_for_save) '.png']);
    print(fig, figure_filename, '-dpng', '-r300');
    fprintf('  - Saved Box Plot figure to %s\n', figure_filename);
end
fprintf('TEST PHASE: All Box Plots generated and saved.\n\n');

%% --- TRAINING PHASE ANALYSIS ---
fprintf('--------------------------------------------------\n');
fprintf('TRAINING PHASE: Starting analysis...\n');

% --- Prep Training Data ---
training_data.group = categorical(training_data.group);

% --- Summarize TRAINING Data per Subject ---
% We average across both training stages (2 and 3) for each subject
training_grouping_vars = {'subject', 'group'};
training_subject_means_table = groupsummary(training_data, training_grouping_vars, 'mean', measures_to_summarize);

% --- Save TRAINING Subject Means Table ---
fprintf('TRAINING PHASE: Saving per-subject means table...\n');
training_means_xlsx_filename = fullfile(data_directory, 'training_subject_means.xlsx');
training_means_mat_filename  = fullfile(data_directory, 'training_subject_means.mat');
writetable(training_subject_means_table, training_means_xlsx_filename);
save(training_means_mat_filename, 'training_subject_means_table');
fprintf('  - Saved to %s and .mat\n\n', training_means_xlsx_filename);

% --- Calculate TRAINING Group-Level Statistics (Mean & SEM) ---
training_vars_from_means = strcat('mean_', measures_to_summarize);
training_grouping_for_plot = {'group'};
training_group_stats_table = groupsummary(training_subject_means_table, training_grouping_for_plot, {'mean', 'std'}, training_vars_from_means);

for i = 1:length(measures_to_summarize)
    original_measure = measures_to_summarize{i};
    std_of_mean_col  = ['std_mean_'  original_measure];
    sem_col_name = ['sem_' original_measure];
    training_group_stats_table.(sem_col_name) = training_group_stats_table.(std_of_mean_col) ./ sqrt(training_group_stats_table.GroupCount);
end

%% --- GENERATE PLOTS FOR TRAINING DATA ---
fprintf('TRAINING PHASE: Generating comparison plots...\n');

for p = 1:length(measures_to_plot)
    
    current_measure = measures_to_plot{p};
    mean_col = ['mean_mean_' current_measure];
    sem_col = ['sem_' current_measure];
    individual_col = ['mean_' current_measure]; 
    
    fig = figure('Position', [100, 100, 600, 500], 'Visible', 'on');
    hold on;
    
    % --- Loop through each group to plot them ---
    for g = 1:numel(group_names)
        current_group = group_names(g);
        
        % --- Plot 1: Mean and SEM ---
        stats_subset = training_group_stats_table(training_group_stats_table.group == current_group, :);
        x_position = g; % Group 1 at x=1, Group 2 at x=2
        
        if ~isempty(stats_subset)
            errorbar(x_position, stats_subset.(mean_col), stats_subset.(sem_col), 'o', 'Color', group_colors(g, :), ...
                'MarkerFaceColor', group_colors(g, :), 'MarkerSize', 6, 'LineWidth', 2, 'CapSize', 15);
        end
        
        % --- Plot 2: Individual Data Points with Jitter ---
        individual_subset = training_subject_means_table(training_subject_means_table.group == current_group, :);
        
        if ~isempty(individual_subset)
            num_points = height(individual_subset);
            jitter = (rand(num_points, 1) - 0.5) * 0.2; % Wider jitter for this plot type
            plot(x_position + jitter, individual_subset.(individual_col), 'o', 'Color', group_colors(g, :), ...
                'MarkerFaceColor', group_colors(g, :), 'MarkerEdgeColor', 'none', 'MarkerSize', 4);
            % Get overall Y-axis limits for consistent scaling across subplots
            all_individual_data = individual_subset.(individual_col);
            y_max = max(all_individual_data) * 1.1;
        
        end
    end
    
    % --- Customize the Plot ---
    hold off;
    title(['Training Phase: ' plot_titles{p}], 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(y_labels{p}, 'FontSize', 12);
    set(gca, 'XTick', [1, 2], 'XTickLabel', cellstr(group_names), 'FontSize', 12);
    xlim([0.5, 2.5]);
    ylim([0, y_max]);
   
    % --- Save TRAINING Figure ---
    figure_title_for_save = strrep(plot_titles{p}, ' ', '_');
    figure_filename = fullfile(data_directory, ['training_plot_' lower(figure_title_for_save) '.png']);
    print(fig,figure_filename,'-dpng', '-r300');
    fprintf('  - Saved figure to %s\n', figure_filename);
end

fprintf('TRAINING PHASE: All plots generated and saved.\n\n');
fprintf('Script finished.\n');