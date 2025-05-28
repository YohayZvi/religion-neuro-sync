function nanInfo = quantify_nans(data, groupName, taskName, printResults)
% -------------------------------------------------------------------
% quantify_nans.m
%
% Quantifies NaN patterns in a 3D fMRI data matrix (voxels × TRs × subjects).
%
% It identifies:
%   • missing_voxels       – voxels that are all NaN across time (i.e.,
%   excluded in preprocessing) 
%   • missing_TRs          – time points that are all NaN across voxels
%   • random_nans          – NaNs that are not part of a missing voxel or TR
%
% Inputs:
%   data          – numeric 3D array (voxels × TRs × subjects)
%   groupName     – char or string, name of the group (for display)
%   taskName      – char or string, name of the task (for display)
%   printResults  – logical or 0/1, whether to print summaries
%
% Output:
%   nanInfo       – struct with one field per subject (Sub_01, Sub_02, …)
%
% Project: Religious-Dependent Neural Synchronization
% Author : Yohay Zvi
% Original Date : March 2023
% Checked : May 2025
% -------------------------------------------------------------------

% Input validation
if ndims(data) ~= 3
    error('quantify_nans:InvalidInput', 'Input `data` must be a 3D matrix.');
end
if ~ischar(groupName) && ~isstring(groupName)
    error('quantify_nans:InvalidInput', '`groupName` must be a char or string.');
end
if ~ischar(taskName) && ~isstring(taskName)
    error('quantify_nans:InvalidInput', '`taskName` must be a char or string.');
end
printResults = logical(printResults);

% Get dimensions
[num_voxels, num_TRs, num_subjects] = size(data);

% Print header
if printResults
    fprintf('Group: %s, Task: %s\n', groupName, taskName);
    fprintf('  %d voxels × %d TRs × %d subjects\n', num_voxels, num_TRs, num_subjects);
end

% Initialize output struct
nanInfo = struct();

% Loop through each subject
for iSub = 1:num_subjects
    subID = sprintf('Sub_%02d', iSub);

    % Identify missing voxels (all NaN across TRs)
    missing_voxels = all(isnan(data(:,:,iSub)), 2);
    missing_voxels_indices = find(missing_voxels);

    % Identify missing TRs (all NaN across voxels)
    missing_TRs = all(isnan(data(:,:,iSub)), 1);
    missing_TRs_indices = find(missing_TRs);

    % Identify random NaNs (not part of missing voxel or TR)
    random_nans = isnan(data(:,:,iSub)) & ~missing_voxels & ~missing_TRs;
    random_nans_indices = find(random_nans);

    % Save into output struct
    nanInfo.(subID).missing_voxels = missing_voxels;
    nanInfo.(subID).missing_voxels_indices = missing_voxels_indices;
    nanInfo.(subID).missing_TRs = missing_TRs;
    nanInfo.(subID).missing_TRs_indices = missing_TRs_indices;
    nanInfo.(subID).random_nans = random_nans;
    nanInfo.(subID).random_nans_indices = random_nans_indices;

    % Print per-subject summary
    if printResults
        fprintf('Subject %02d:\n', iSub);
        fprintf('  missing voxels: %d\n', nnz(missing_voxels));
        fprintf('  missing TRs   : %d\n', nnz(missing_TRs));
        fprintf('  random NaNs   : %d\n', nnz(random_nans));

        % Warning for missing TRs
        if nnz(missing_TRs) ~= 0
            warning('quantify_nans:MissingTRs', ...
                ['Group: %s, Task: %s, Subject %02d has %d missing TRs. ', ...
                 'Consider mean imputation, interpolation, or model-based imputation.'], ...
                 groupName, taskName, iSub, nnz(missing_TRs));
        end
    end
end
