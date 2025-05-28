% -------------------------------------------------------------------
% run_SVM_classification.m
%
% Predicts group labels (Religious vs Secular) for each voxel based on ISC scores.
% Workflow:
%   1. Load within‐group ISC values and significance masks
%   2. Select voxels significant in either group
%   3. Perform leave‐two‐out SVM classification per voxel
%   4. Save accuracy matrices to results/svm/
%   5. Convert mean accuracies into NIfTI maps under results/svm/Nifti/
%
% Project: Religious-Dependent Neural Synchronization
% Author : Yohay Zvi
% Date   : May 9, 2024
% Checked: May 2025
% -------------------------------------------------------------------

clear; clc;

%% 1. Define root and sub-directory paths
rootDir   = fileparts(fileparts(fileparts(mfilename('fullpath'))));  
isc_path  = fullfile(rootDir, 'results', 'isc');   % ISC results
save_path = fullfile(rootDir, 'results', 'svm');   % SVM outputs

%% 2. Analysis settings
videos      = ["neutral" "kosher", "hammetz"];
groupsNames = ["Religious", "Secular"];

%% 3. Loop over videos and groups for classification
for vid_i = 1:numel(videos)
    fprintf('\n=== SVM classification for %s (%d of %d) ===\n', ...
        videos(vid_i), vid_i, numel(videos));
    tic;
    
    % Load ISC values and significance masks
    load(fullfile(isc_path, sprintf('W_ISC_Religious_%s', videos(vid_i))), 'W_ISC_values', 'sigindx');
    religious_isc = W_ISC_values;  
    religious_sig = sigindx;
    load(fullfile(isc_path, sprintf('W_ISC_Secular_%s', videos(vid_i))), 'W_ISC_values', 'sigindx');
    secular_isc = W_ISC_values;  
    secular_sig = sigindx;
    
    % Select voxels significant in either group
    sig_vox = logical(religious_sig + secular_sig);
    religious_isc = religious_isc(sig_vox, :);
    secular_isc    = secular_isc(sig_vox, :);
    clear W_ISC_values sigvals sigindx mean_ISC_within qcrit pvalues pcrit
    
    % Perform SVM classification (leave-2-out)
    [acc_mat, mean_acc] = SVM_L2out(religious_isc, secular_isc);
    
    % Save results
    saveName = fullfile(save_path, sprintf('SVM_2out_Religious_Secular_%s', videos(vid_i)));
    save(saveName, 'acc_mat', 'mean_acc', 'sig_vox');
    
    fprintf('Completed in %.2f hours\n', toc/3600);
end

%% 4. Create NIfTI maps of mean accuracy
clear; clc;

% Redefine videos for NIfTI stage
videos = ["neutral", "kosher", "hammetz"];

% Paths for input data and NIfTI output
rootDir      = fileparts(fileparts(fileparts(mfilename('fullpath'))));
input_data   = fullfile(rootDir, 'results', 'svm');            % .mat files
outputPath   = fullfile(rootDir, 'results', 'svm', 'Nifti');    % NIfTI maps
nifti_utils  = fullfile(rootDir, 'code', 'utils', 'nifti');     % values_to_nifti

addpath(genpath(nifti_utils));

filePrefix = 'SVM_2out_Religious_Secular_';
mm         = 2;

for vid_i = 1:numel(videos)
    fprintf('\nGenerating NIfTI for %s...\n', videos(vid_i));
    
    % Load classification results
    dataFile = fullfile(input_data, strcat(filePrefix, videos(vid_i)));
    load(dataFile, 'mean_acc', 'sig_vox');
    
    % Prepare volume vector
    to_be_transferred = zeros(size(sig_vox));
    to_be_transferred(sig_vox) = mean_acc;
    
    % Path to kept-vox mask
    collective_keptVox_path = fullfile(rootDir, 'data', 'fMRI', 'kept_vox', ...
        sprintf('unifyKeptVox_%s.mat', videos(vid_i)));
    
    % Call helper to write NIfTI
    values_to_nifti( ...
        to_be_transferred, mm, collective_keptVox_path, ...
        outputPath, [filePrefix videos(vid_i)], true ...
    );
end
