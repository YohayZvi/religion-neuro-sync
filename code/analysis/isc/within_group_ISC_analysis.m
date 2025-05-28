% -------------------------------------------------------------------
% within‐group_ISC_main.m
% 
% This code conducts the full Within‐Group Inter‐Subject Correlation
% analysis for the Religious and Secular groups.
%
% It performs the following stages:
% (a) NaNs sanity check for the input data (`dataMat_combined`)
% (b) Calls the W-ISC function to compute within‐group ISC
% (c) Loads pre-computed null distributions and computes p-values
% (d) Applies FDR correction and saves thresholded NIfTI maps
% (e) Saves ISC values and significance masks for each group/video
%
% Project: Religious‐Dependent Neural Synchronization
% Author: Yohay Zvi
% Original Date: July 2023
% Checked: May 2025
% -------------------------------------------------------------------

clear; clc

%% Project paths (relative to this script’s location)

% 1. Find the folder containing this script
scriptPath = mfilename('fullpath');
if isempty(scriptPath)
    % fallback if run as a script rather than function
    scriptPath = which('within_group_ISC_analysis');
end
scriptDir = fileparts(scriptPath);

% 2. Climb up: isc → analysis → code → repo root
iscDir   = scriptDir;                         % .../code/analysis/isc
analysisDir = fileparts(iscDir);              % .../code/analysis
codeDir     = fileparts(analysisDir);         % .../code
rootDir     = fileparts(codeDir);             % → your repo root

% 3. Now build all the other paths relative to rootDir
data_path      = fullfile(rootDir,'data','fMRI','data_mat_combined');
keptVox_path   = fullfile(rootDir,'data','fMRI','kept_vox');
nullDist_path  = fullfile(rootDir,'data','fMRI','null_dist','isc');
output_path    = fullfile(rootDir,'results','isc');
nifti_path     = fullfile(rootDir,'code','utils','nifti');
isc_code_path  = fullfile(rootDir,'code','analysis','isc');

% 4. Add your toolboxes / helper code
addpath(genpath(nifti_path));
addpath(genpath(isc_code_path));

%% Analysis settings
groups       = ["Religious", "Secular"];
videos       = ["neutral", "kosher", "hammetz"];
mm           = 2;                 % NIfTI voxel resolution (mm)
qcrits       = [0.001, 0.0005];   % FDR q-values
printResults = true;              % print NaN summary

% Ensure output directory exists
if ~exist(output_path,'dir')
    mkdir(output_path);
end

%% Within‐Group ISC computation
for gi = 1:numel(groups)
    grp = groups(gi);
    for vi = 1:numel(videos)
        vid = videos(vi);

        % (a) Load preprocessed data matrix
        datFile = sprintf("%s_Combined_task_%s.mat", grp, vid);
        tmp     = load(fullfile(data_path, datFile), 'dataMat_combined');
        dataMat_combined = tmp.dataMat_combined;

        % (b) NaNs sanity check
        quantify_nans(dataMat_combined, grp, vid, printResults);

        % (c) Compute ISC
        [mean_ISC_within, W_ISC_values] = within_ISC_YZ_fast(dataMat_combined);

        % (d) Write raw ISC to NIfTI
        niftiOutDir = fullfile(output_path,'nifti');
        if ~exist(niftiOutDir,'dir')
            mkdir(niftiOutDir);
        end
        keptVoxFile = fullfile(keptVox_path, sprintf("unifyKeptVox_%s.mat", vid));
        values_to_nifti( mean_ISC_within, mm, keptVoxFile, niftiOutDir, ...
                         sprintf("mean_ISC_%s_%s", grp, vid), true );

        % (e) Load null distribution and compute p-values
        ndFile  = sprintf("W_ISC_nullDist_%s_%s.mat", grp, vid);
        ND      = load(fullfile(nullDist_path, ndFile), 'nullDist');
        pvalues = theoretic_pvalues(ND.nullDist, mean_ISC_within);

        % (f) FDR and thresholded NIfTI maps
        for q = qcrits
            [pcrit, sigvals, sigindx] = fdr_BH(pvalues, q);
            masked = mean_ISC_within;
            masked(~sigindx) = 0;
            values_to_nifti( masked, mm, keptVoxFile, niftiOutDir, ...
                             sprintf("mean_ISC_%s_%s_afterFDR_%.4f", grp, vid, q), true );
        end

        % (g) Save results
        saveFile = fullfile(output_path, sprintf("W_ISC_%s_%s", grp, vid));
        save(saveFile, 'W_ISC_values', 'mean_ISC_within', 'pvalues', ...
                         'pcrit', 'sigvals', 'sigindx', 'q');
    end
end
