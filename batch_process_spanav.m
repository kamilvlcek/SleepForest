% =========================================================================
%
% This script automates the analysis of spatial navigation data for all
% subjects and consolidates the results into one large table
%
% 1. Identifies all unique subjects in a specified data directory
% 2. For each subject and each phase (2, 3, 4), it finds all matching
%    log files and selects the largest one for processing
% 3. Extracts a specific subset of columns from the analysis output
% 4. Adds new columns for 'subject' ID and 'teststage' (2, 3, or 4)
% 5. Aggregates all trial data from all subjects into a single table
% 6. Saves the final consolidated table to a single Excel file and mat file
% 7. Creates a detailed log file ('processing_log.txt') to track progress,
%    file selection, and report errors
%
% =========================================================================

clear;
clc;
close all;

%% --- Configuration ---
% set paths 
data_directory   = 'E:\work\Sleep project\sleepforest\all_spanav_raw_data';
output_directory = 'E:\work\Sleep project\sleepforest\processed_spanav_results';

% Create the output directory if it doesn't exist
if ~exist(output_directory, 'dir')
    mkdir(output_directory);
end

%% --- 1. Setup Logging ---
log_filename = fullfile(output_directory, 'processing_log.txt');
logFileID = fopen(log_filename, 'w');
cleanupObj = onCleanup(@() fclose(logFileID));
log_message = @(message) [fprintf('%s\n', message), fprintf(logFileID, '%s\n', message)];

log_message(sprintf('Batch processing started at: %s', datetime('now')));
log_message('==================================================');

%% --- 2. Find Unique Subjects ---
log_message(sprintf('Scanning for subjects in: %s', data_directory));
all_files = dir(fullfile(data_directory, '*.tr'));
if isempty(all_files)
    error_msg = 'No .tr files found. Check the data_directory and file naming convention.';
    log_message(['ERROR: ' error_msg]);
    error(error_msg);
end
subject_ids = cellfun(@(x) strsplit(x, '_'), {all_files.name}, 'UniformOutput', false);
subject_ids = cellfun(@(x) x{1}, subject_ids, 'UniformOutput', false);
unique_subject_ids = unique(subject_ids);
log_message(sprintf('Found %d unique subjects.\n', length(unique_subject_ids)));


%% --- 3. Initialize Data Collection and Define Headers ---
final_headers = {'subject', 'teststage', 'trial', 'aim', 'animal', 'North_marked', 'Statues_present', ...
                 'aim_found', 'duration', 'length', 'path_deviation', 'errors', ...
                 'StartField', 'GoalField', 'N_trained_pairs', 'N_turns', 'Level_type', ...
                 'angle_indicated', 'angle_real', 'angle_error', 'path_efficiency'};
column_indices_to_keep = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 21];
all_data_combined = final_headers;

subjects_processed_successfully = 0;

%% --- 4. Process Each Subject ---
for i = 1:length(unique_subject_ids)
    subject_id = unique_subject_ids{i};
    log_message('--------------------------------------------------');
    log_message(sprintf('Processing Subject: %s (%d/%d)', subject_id, i, length(unique_subject_ids)));

    files_processed_for_this_subject = 0;
 
    phase_numbers = [2, 3, 4]; % Train 1, Train 2, Test

    % --- Loop through the three phases for the current subject ---
    for j = 1:length(phase_numbers)
        current_phase = phase_numbers(j);
        
        % --- File selection logic ---
        search_pattern = sprintf('%s_%d_*.tr', subject_id, current_phase);
        full_search_path = fullfile(data_directory, search_pattern);
        matching_files = dir(full_search_path);
        
        if isempty(matching_files)
            log_message(sprintf('  - Phase %d: No files found matching "%s". Skipping.', current_phase, search_pattern));
            continue;
        elseif length(matching_files) == 1
            selected_filename = matching_files.name;
            log_message(sprintf('  - Phase %d: Found 1 file. Selecting: %s', current_phase, selected_filename));
        else
            log_message(sprintf('  - Phase %d: Found %d files. Checking sizes...', current_phase, length(matching_files)));
            for k = 1:length(matching_files)
                log_message(sprintf('    - %s (Size: %.2f KB)', matching_files(k).name, matching_files(k).bytes / 1024));
            end
            [~, max_idx] = max([matching_files.bytes]);
            selected_filename = matching_files(max_idx).name;
            log_message(sprintf('  -> Phase %d: Selecting largest file: %s', current_phase, selected_filename));
        end

        full_filepath = fullfile(data_directory, selected_filename);
        log_message(sprintf('    - Reading file: %s', selected_filename));
        
        try
            out = ReadTR3(full_filepath, [], [], [], 0,0);
        catch ME
            log_message(sprintf('    - !!! ERROR processing file %s. Skipping. !!!', selected_filename));
            log_message(sprintf('      Error message: %s', ME.message));
            continue;
        end

        % --- data extraction ---
        if size(out, 1) < 3
            log_message('    - No trial data found in this file.');
            continue;
        end
        potential_trials_block = out(3:end, :);
        is_valid_trial_row = cellfun(@(c) isnumeric(c) && ~isempty(c) && isscalar(c), potential_trials_block(:, 1));
        trial_data = potential_trials_block(is_valid_trial_row, :);
        
        if isempty(trial_data)
            log_message('    - No valid trial data rows found in this file.');
            continue;
        end
        
        num_trials = size(trial_data, 1);
        log_message(sprintf('    - Successfully processed %d trials.', num_trials));
        
        % --- Create and append the data block ---
        subject_col = repmat({subject_id}, num_trials, 1);
        stage_col = repmat({current_phase}, num_trials, 1);
        selected_data = trial_data(:, column_indices_to_keep);
        new_data_block = [subject_col, stage_col, selected_data];
        all_data_combined = [all_data_combined; new_data_block]; %#ok<AGROW>
        
        files_processed_for_this_subject = files_processed_for_this_subject + 1;
        
    end % End of loop for phases (2, 3, 4)
    
    % Check if all 3 files were processed for this subject  
    if files_processed_for_this_subject == 3
        subjects_processed_successfully = subjects_processed_successfully + 1;
    end
    
end % End of loop for subjects

%% --- 5. Finalize and Save the Output ---
log_message('--------------------------------------------------');
log_message('All subjects processed. Consolidating final output...');

if size(all_data_combined, 1) <= 1
    log_message('WARNING: No data was collected from any files. No output file will be generated.');
else
    all_data_table = cell2table(all_data_combined(2:end,:), 'VariableNames', all_data_combined(1,:));
    
    % --- Robust data type conversion ---
    numeric_vars = {'teststage', 'trial', 'North_marked', 'Statues_present', 'aim_found', ...
                    'duration', 'length', 'path_deviation', 'errors', 'StartField', 'GoalField', ...
                    'N_trained_pairs', 'N_turns', 'Level_type', 'angle_indicated', 'angle_real', ...
                    'angle_error', 'path_efficiency'};
                    
    for k = 1:length(numeric_vars)
        var_name = numeric_vars{k};
        if iscell(all_data_table.(var_name))
            temp_col = all_data_table.(var_name);
            is_bad_cell = cellfun(@(c) ~isnumeric(c) || isempty(c) || ~isscalar(c), temp_col);
            temp_col(is_bad_cell) = {NaN};
            all_data_table.(var_name) = cell2mat(temp_col);
        end
    end

    
    try
        % Define filenames for both formats
        output_xlsx_filename = fullfile(output_directory, 'all_subjects_data.xlsx');
        output_mat_filename  = fullfile(output_directory, 'all_subjects_data.mat');
        
        % 1. Save to Excel file
        writetable(all_data_table, output_xlsx_filename, 'Sheet', 'All_Trials');
        
        % 2. Save to MAT file
        save(output_mat_filename, 'all_data_table');
        
        % 3. Report success for both
        log_message(sprintf('Successfully processed %d subjects (with all 3 files) and consolidated data for %d trials.', ...
            subjects_processed_successfully, size(all_data_table,1)));
        log_message('Data saved to:');
        log_message(output_xlsx_filename);
        log_message(output_mat_filename);

    catch ME
        log_message('!!! FAILED TO WRITE FINAL OUTPUT FILES !!!');
        log_message(sprintf('    Error message: %s', ME.message));
        log_message('The final data is available in the MATLAB workspace as the variable ''all_data_table''.');
    end
end

log_message('==================================================');
log_message(sprintf('Batch processing finished at: %s', datetime('now')));
    