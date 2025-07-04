% =========================================================================
% 
% This script takes the experimental data table of all subjects and merges it
% with a separate file containing subject group assignments (and also other
% metadata in the future)
%
% STEPS:
% 1. Loads the 'all_subjects_data.mat' file (containing the main data table)
% 2. Loads an Excel file with subject IDs and their corresponding groups
% 3. Performs a 'left join' to add the group information as new columns
%    to the main data table
% 4. Cleans up and reorders the columns for clarity
% 5. Saves the newly augmented table to new .mat and .xlsx files with
%    a "_with_groups" suffix
%
% =========================================================================

clear;
clc;
fprintf('Starting script to add group information...\n\n');

%% --- Configuration ---
% set paths 

% Directory where 'all_subjects_data.mat' and group file are located
data_directory = 'E:\work\Sleep project\sleepforest\processed_spanav_results';
main_data_filename = 'all_subjects_data.mat';
group_info_filename = 'subjects_list.xlsx';

%% --- 1. Load Input Data ---

% --- Load the main data table from the .mat file ---
main_data_filepath = fullfile(data_directory, main_data_filename);
if ~exist(main_data_filepath, 'file')
    error('Main data file not found: %s', main_data_filepath);
end
fprintf('Loading main data table from: %s\n', main_data_filepath);
load(main_data_filepath, 'all_data_table'); 

% --- Load the group information from the Excel file ---
group_info_filepath = fullfile(data_directory, group_info_filename);
if ~exist(group_info_filepath, 'file')
    error('Group assignment file not found: %s', group_info_filepath);
end
fprintf('Loading group assignments from: %s\n', group_info_filepath);
group_info_table = readtable(group_info_filepath);

fprintf('Data loaded successfully.\n\n');

%% --- 2. Perform the Merge (Join) ---
fprintf('Merging tables based on subject ID...\n');

try
    augmented_table = join(all_data_table, group_info_table, ...
                           'LeftKeys', 'subject', ...
                           'RightKeys', 'ID');
catch ME
    fprintf('ERROR: The join operation failed. \n');
    fprintf('Please check that the key column names are correct in the script.\n');
    fprintf('  - Key in main data table: ''subject''\n');
    fprintf('  - Key in group info file: ''ID''\n');
    rethrow(ME);
end

% Check if the join was successful
if height(augmented_table) ~= height(all_data_table)
    warning('The number of rows changed after the join. Check for unexpected key matches.');
end

fprintf('Merge complete.\n\n');

%% --- 3. Clean Up and Reorder Columns ---
fprintf('Cleaning and reordering the final table...\n');

if ismember('ID', augmented_table.Properties.VariableNames)
    augmented_table.ID = [];
end

% Define the desired column order for the final table.
original_vars = all_data_table.Properties.VariableNames;
new_order = ['subject', 'skupina', 'group', original_vars(2:end)]; % Skip the original 'subject'

% Reorder the table
final_table = augmented_table(:, new_order);

fprintf('Final table prepared with %d rows and %d columns.\n\n', height(final_table), width(final_table));


%% --- 4. Save the Final Augmented Table ---
% Create new filenames with a "_with_groups" suffix.
output_xlsx_filename = fullfile(data_directory, 'all_subjects_data_with_groups.xlsx');
output_mat_filename  = fullfile(data_directory, 'all_subjects_data_with_groups.mat');

fprintf('Saving augmented data to new files...\n');

try
    % --- Save to Excel file ---
    writetable(final_table, output_xlsx_filename, 'Sheet', 'All_Trials');
    fprintf('  - Successfully saved Excel file to: %s\n', output_xlsx_filename);

    % --- Save to .mat file ---
    save(output_mat_filename, 'final_table');
    fprintf('  - Successfully saved .mat file to:  %s\n', output_mat_filename);
    
catch ME
    fprintf('!!! ERROR: FAILED TO WRITE FINAL OUTPUT FILES !!!\n');
    fprintf('    Error message: %s\n', ME.message);
    fprintf('The final data is available in the MATLAB workspace as the variable ''final_table''.\n');
end

fprintf('\nScript finished successfully.\n');