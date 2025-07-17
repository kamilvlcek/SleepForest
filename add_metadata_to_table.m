function final_table = add_metadata_to_table(main_data_filepath, metadata_filepath, output_directory)
% =========================================================================
% This function merges experimental spanav data (obtained in batch_process_spanav) with subject metadata from an Excel file
% (currently only subject group assignments, but also other metadata in the future)
%
% 1. Loads the 'all_subjects_data.mat' file (containing the main data table)
% 2. Loads an Excel file with subject IDs and their corresponding groups
% 3. Performs a 'left join' to add the group information as new columns
%    to the main data table
% 4. Cleans up and reorders the columns for clarity
% 5. Saves the new output table to new .mat and .xlsx files with
%    a "_with_groups" suffix
%
%   INPUTS:
%       main_data_filepath (string):
%           The full path to the .mat file containing main experimental data table (e.g., all_subjects_data.mat)
%           Example: 'E:\work\Sleep project\sleepforest\processed_spanav_results\all_subjects_data.mat'
%
%       metadata_filepath (string):
%           The full path to the Excel file (.xlsx) containing the metadata
%           Example: 'E:\work\Sleep project\sleepforest\processed_spanav_results\subjects_list.xlsx'
%
%       output_directory (string):
%           The full path to the folder where the final results will be saved
%           Example: 'E:\results'
%
%   OUTPUTS:
%       output_table (table):
%       	The new, merged MATLAB table containing the original data plus the new metadata columns
%           all_subjects_data_with_groups.xlsx and all_subjects_data_with_groups.mat
%
%   Example Usage:
%       main_file = 'E:\work\Sleep project\sleepforest\processed_spanav_results\all_subjects_data.mat';
%       meta_file = 'E:\work\Sleep project\sleepforest\processed_spanav_results\subjects_list.xlsx';
%       out_dir   = 'E:\work\Sleep project\sleepforest\processed_spanav_results';
%
%       final_data = add_metadata_to_table(main_file, meta_file, out_dir);
% =========================================================================

% --- 1. Load Input Data ---

% --- Load the main data table from the .mat file ---
if ~exist(main_data_filepath, 'file')
    error('Main data file not found: %s', main_data_filepath);
end
fprintf('Loading main data table from: %s\n', main_data_filepath);
loaded_data = load(main_data_filepath, 'all_data_table');
data_table = loaded_data.all_data_table;

% --- Load the group information from the Excel file ---
if ~exist(metadata_filepath, 'file')
    error('Group assignment file not found: %s', metadata_filepath);
end
fprintf('Loading group assignments from: %s\n', metadata_filepath);
metadata_table = readtable(metadata_filepath);

fprintf('Data loaded successfully.\n\n');

% --- 2. Perform the Merge (Join) ---
fprintf('Merging tables based on subject ID...\n');

% key column names
data_key_column = 'subject';
metadata_key_column = 'ID';
try
    output_table = join(data_table, metadata_table, ...
        'LeftKeys', data_key_column, ...
        'RightKeys', metadata_key_column);
catch ME
    fprintf('ERROR: The join operation failed. \n');
    fprintf('Please check that the key column names are correct (hardcoded as ''%s'' and ''%s'').\n', data_key_column, metadata_key_column);
    rethrow(ME);
end

% Check if the join was successful
if height(output_table) ~= height(data_table)
    warning('The number of rows changed after the join. Check for unexpected key matches.');
end

fprintf('Merge complete.\n\n');

% --- 3. Clean Up and Reorder Columns ---
fprintf('Cleaning and reordering the final table...\n');

if ismember(metadata_key_column, output_table.Properties.VariableNames)
    output_table.(metadata_key_column) = [];
end

% Define the desired column order for the final table.
original_vars = data_table.Properties.VariableNames;
new_vars = setdiff(output_table.Properties.VariableNames, original_vars, 'stable');
new_order = [original_vars(1), new_vars, original_vars(2:end)];

% Reorder the table
final_table = output_table(:, new_order);

fprintf('Final table prepared with %d rows and %d columns.\n\n', height(final_table), width(final_table));


% --- 4. Save the Final Table ---
% Create new filenames with a "_with_groups" suffix.
output_xlsx_filename = fullfile(output_directory, 'all_subjects_data_with_groups.xlsx');
output_mat_filename  = fullfile(output_directory, 'all_subjects_data_with_groups.mat');

fprintf('Saving merged data to new files...\n');

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

end
