% -------------------------------------------------------------------
% SVM_class_nullDist.m
%
% Generates a null distribution for SVM classification via label shuffling.
%
% Purpose:
%   Estimate the chance-level accuracy of a linear SVM classifier under
%   random label assignments. For each voxel, labels are shuffled and the
%   classifier is trained and tested on the full dataset (no train/test split).
%
% Usage:
%   acc_mat = SVM_class_nullDist(group1, group2, num_shuf);
%
% Inputs:
%   group1   – numeric matrix (voxels × subjects) for group 1 (e.g., ISC scores)
%   group2   – numeric matrix (voxels × subjects) for group 2
%   num_shuf – integer, number of permutations (label‐shuffling iterations)
%
% Output:
%   acc_mat  – numeric matrix (voxels × num_shuf) of classification accuracies
%
% Notes:
%   • Overfitting is intentional for null estimation—no train/test split.  
%   • Accuracy is computed as proportion of correctly predicted labels.  
%
% Project: Religious-Dependent Neural Synchronization
% Author : Yohay Zvi
% Date   : May 2024
% Checked: May 2025
% -------------------------------------------------------------------

function acc_mat = SVM_class_nullDist(group1, group2, num_shuf)

%% 1. Prepare data and labels
numVox   = size(group1, 1);
numSub1  = size(group1, 2);
numSub2  = size(group2, 2);
N        = numSub1 + numSub2;
labels   = [zeros(numSub1,1); ones(numSub2,1)];  % 0 = group1, 1 = group2
data     = [group1, group2];                     % voxels × N
acc_mat  = nan(numVox, num_shuf);                % preallocate

%% 2. Permutation loop
for iter_i = 1:num_shuf
    % Set reproducible seed per iteration
    rng(iter_i + num_shuf, 'twister');
    
    % Shuffle labels
    shuffled_labels = labels(randperm(N));
    
    % Loop over voxels
    for vox_i = 1:numVox
        % Train linear SVM on all data with shuffled labels
        SVM_model = fitcsvm(data(vox_i, :)', shuffled_labels, ...
                            'KernelFunction', 'linear');
        % Predict on the same data
        preds = predict(SVM_model, data(vox_i, :)');
        % Compute accuracy (correct predictions / total)
        acc_mat(vox_i, iter_i) = sum(preds == shuffled_labels) / N;
    end
end

end
