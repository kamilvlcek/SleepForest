% =========================================================================
% This script demonstrates how to use the 'analyze_and_plot_results' function
% to perform different analyses on the spatial navigation data
% =========================================================================

clear;
clc;
close all;

% --- Set up Paths ---

% Full path to the .mat file containing the data table from all subjects with groups
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
