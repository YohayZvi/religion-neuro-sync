function [mean_ISC_within, W_ISC_values] = within_ISC_YZ_fast(data)
% -------------------------------------------------------------------
% within_ISC_YZ_fast.m
%
% Calculates within-group Inter-Subject Correlation (ISC) values.
%
% Purpose:
%   Computes ISC on a 3D data matrix (voxels × TRs × subjects) using a
%   leave-one-out paradigm: for each subject, correlates that subject's
%   time-course with the mean time-course of the group excluding that subject.
%
% Inputs:
%   data            – numeric 3D array (voxels × TRs × subjects)
%
% Outputs:
%   mean_ISC_within – (voxels × 1) vector of mean ISC across subjects
%   W_ISC_values    – (voxels × subjects) matrix of ISC per subject
%
% Notes:
%   • This function does not handle missing TRs or random NaNs; ensure
%     data is free of NaNs using `quantify_nans` prior to calling.
%
% Project: Religious-Dependent Neural Synchronization
% Author : Yohay Zvi
% Original Date : March 2023
% Checked : May 2025
% -------------------------------------------------------------------

% Input validation
if ndims(data) ~= 3
    error('within_ISC_YZ_fast:InvalidInput', 'Input `data` must be a 3D matrix.');
end
[num_voxels, num_TRs, num_subjects] = size(data);
if num_TRs < num_subjects
    error('within_ISC_YZ_fast:InvalidInput', ...
        'Data dimensions must be voxels × TRs × subjects.');
end

% Initialize output
W_ISC_values = nan(num_voxels, num_subjects);

% Compute ISC values for each subject
for iSub = 1:num_subjects
    % Exclude current subject to compute mean time-course
    group_wo_sub = data;
    group_wo_sub(:,:,iSub) = [];
    sub_data = data(:,:,iSub);
    mean_timeCourse_wo_sub = mean(group_wo_sub, 3, 'omitnan');
    
    % Center the data
    group_mean_centered = mean_timeCourse_wo_sub - ...
        mean(mean_timeCourse_wo_sub, 2, 'omitnan');
    sub_centered = sub_data - mean(sub_data, 2, 'omitnan');
    
    % Compute correlation per voxel
    W_ISC_values(:,iSub) = ...
        dot(group_mean_centered, sub_centered, 2) ./ ...
        sqrt(dot(group_mean_centered, group_mean_centered, 2) .* ...
             dot(sub_centered, sub_centered, 2));
end

% Mean across subjects
mean_ISC_within = mean(W_ISC_values, 2, 'omitnan');
