% =========================================================================
% This script demonstrates how to process raw spanav data by creating a large table for all subjects, 
% merging it with group assignments and creating different figures on aggregated data (test/training)
% =========================================================================

%% clear everything
clear;
clc;
close all;

%% run the analysis of spatial navigation data for all subjects and consolidates the results into one large table

% The full path to the folder containing the raw .tr data files for all subjects
raw_path = 'E:\work\Sleep project\sleepforest\all_spanav_raw_data';

% The full path to the folder where the processed results (xls table, .mat file, and log file) will be saved
results_path = 'E:\work\Sleep project\sleepforest\processed_spanav_results';

all_data_table = batch_process_spanav(raw_path, results_path);

%% merge experimental spanav data (obtained by batch_process_spanav) with subject groups from an Excel file
main_file = 'E:\work\Sleep project\sleepforest\processed_spanav_results\all_subjects_data.mat';
meta_file = 'E:\work\Sleep project\sleepforest\processed_spanav_results\subjects_list.xlsx'; % xls with subject groups

final_data = add_metadata_to_table(main_file, meta_file, results_path);

%% create plots and tables with aggregated data for training and test

% Full path to the .mat file containing the data table from all subjects with groups (obtained by add_metadata_to_table)
data_file = 'E:\work\Sleep project\sleepforest\processed_spanav_results\all_subjects_data_with_groups.mat';
% Full path to the folder where output files will be saved
output_dir = 'E:\work\Sleep project\sleepforest\analysis_output';

% --- Run Analyses ---

% 1. Analyze TEST phase data and generate Mean/SEM plots with individual data points with saving all files
analyze_and_plot_results(data_file, output_dir, 'test', 'mean_sem', 1);

% 2. Analyze TEST phase data and generate Boxplots with median with saving all files
analyze_and_plot_results(data_file, output_dir, 'test', 'boxplot', 1);

% 3. Analyze TRAINING phase data and generate with individual data points with saving all files
analyze_and_plot_results(data_file, output_dir, 'training', 'mean_sem', 1);

% 4. Analyze TRAINING phase data and generate Boxplots with median with saving all files
analyze_and_plot_results(data_file, output_dir, 'training', 'boxplot', 1);

%% analyze and visualize the memory change between test and training (L1 pairs)
% shows the direct change from Training to Test for each subject, without stats
calculate_plot_memory_change(data_file, output_dir, 0, 0); 

% shows the summary (Mean/SEM) of the calculated change scores for each group with individual points; performs the Mann-Whitney U tests on change
calculate_plot_memory_change(data_file, output_dir, 1, 1); 


%% visualize the learning curves from the training phase
analyze_training_learning(data_file, output_dir);

%% visualize the learning curves from the test phase (separate for North and Statues condition)
analyze_test_phase_learning(data_file, output_dir);

%% analyze and visualize the memory change between test and training (including L2 and L3 pairs) %09.09.2025
% shows the Mean/SEM of the calculated change scores for each group with individual points separately for each level and cue condition; performs the Mann-Whitney U tests on change
calculate_advanced_memory_change(data_file, output_dir,1);

% for each level of difficulty, it uses a specific training baseline:
%          - L1 BASELINE: Performance on the LAST training trial of the exact same path (e.g., A->B)
%          - L2 BASELINE: The AVERAGE performance of the LAST training trials of the two constituent L1 components (e.g., A->B and B->C for an A->C test trial)
%          - L3 BASELINE: The AVERAGE performance of the LAST training trials of all unique L1 paths (8 pairs), serving as a global baseline
