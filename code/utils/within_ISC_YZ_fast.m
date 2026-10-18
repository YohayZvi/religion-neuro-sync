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
%   • Voxels missing (NaN) in some subjects are averaged over the subjects
%     that have them ('omitnan'); a voxel missing in the left-out subject
%     gets ISC = NaN for that subject. Check NaN patterns with
%     `quantify_nans` first.
%   • Memory (Oct 2026): the leave-one-out mean is computed as
%     (sum over all subjects - left-out subject) / (count - 1) instead of
%     copying the data without the subject (the copy needed ~3x the size of
%     the data, ~15 GB for one group x video). Same result up to floating-
%     point rounding (~1e-16); needs the data plus ~2 GB.
%
% Project: Religious-Dependent Neural Synchronization
% Author : Yohay Zvi
% Original Date : March 2023
% Checked : May 2025; memory revision Oct 2026
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

% Sum and number of non-missing values over all subjects (voxels × TRs)
group_sum   = sum(data, 3, 'omitnan');
group_count = sum(~isnan(data), 3);

% Initialize output
W_ISC_values = nan(num_voxels, num_subjects);

% Compute ISC values for each subject
for iSub = 1:num_subjects
    sub_data = data(:,:,iSub);
    sub_ok   = ~isnan(sub_data);
    sub_zero = sub_data;  sub_zero(~sub_ok) = 0;

    % Mean time-course of the group without the current subject
    % (= mean(data without iSub, 3, 'omitnan'))
    mean_timeCourse_wo_sub = (group_sum - sub_zero) ./ (group_count - sub_ok);

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
