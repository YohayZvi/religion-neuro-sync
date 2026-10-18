function [acc_mat, acc_mean] = SVM_L2out(group1, group2)
% -------------------------------------------------------------------
% SVM_L2out.m
%
% Performs binary SVM classification between two groups of voxelwise ISC scores
% using a leave-2-out cross-validation scheme.
%
% For each voxel:
%   – Leave out one subject from each group as test data  
%   – Train a linear SVM on the remaining subjects  
%   – Predict the held-out pair and record accuracy (0, 0.5, or 1)
%
% Usage:
%   [acc_mat, acc_mean] = SVM_L2out(group1, group2);
%
% Inputs:
%   group1 – numeric matrix (voxels × subjects) ISC scores for group 1  
%   group2 – numeric matrix (voxels × subjects) ISC scores for group 2  
%
% Outputs:
%   acc_mat  – matrix (voxels × combinations) of accuracy values per held-out pair  
%   acc_mean – vector (voxels × 1) of mean accuracy per voxel  
%
% Notes:
%   • NaNs in the input are ignored during training; they propagate as NaNs in acc_mat and are omitted in acc_mean.  
%   • Progress is displayed every 1000 voxels with estimated remaining time.  
%
% Project: Religious-Dependent Neural Synchronization  
% Author : Yohay Zvi  
% Date   : May 9, 2024  
% Checked: May 2025  
% -------------------------------------------------------------------

    % Extract dimensions
    [numVox, numSub1] = size(group1);
    numSub2 = size(group2, 2);

    % Preallocate accuracy matrix
    totalComb = numSub1 * numSub2;
    acc_mat    = nan(numVox, totalComb);

    % Start timer for progress estimates
    tic;

    % Loop over voxels
    for vox_i = 1:numVox
        comboIdx = 1;

        % Display progress every 1000 voxels
        if mod(vox_i, 1000) == 0
            elapsed       = toc;
            timePerVoxel  = elapsed / vox_i;
            timeRemaining = (numVox - vox_i) * timePerVoxel;
            fprintf( ...
                'Voxel %d/%d – est. %.2f hrs remaining\n', ...
                vox_i, numVox, timeRemaining / 3600 ...
            );
        end

        % Loop over leave-one-out pairs
        for i1 = 1:numSub1
            % Prepare group1 training data
            train1 = group1(vox_i, :);
            train1(i1) = [];

            for i2 = 1:numSub2
                % Prepare group2 training data
                train2 = group2(vox_i, :);
                train2(i2) = [];

                % Combine training data and labels
                trainData   = [train1, train2]';
                trainLabels = [zeros(numSub1-1,1); ones(numSub2-1,1)];

                % Fit linear SVM
                SVM_model = fitcsvm(trainData, trainLabels, 'KernelFunction', 'linear');

                % Test on held-out pair
                testData = [group1(vox_i, i1), group2(vox_i, i2)]';
                preds    = predict(SVM_model, testData);

                % Assign accuracy: 1 = correct both, 0.5 = one correct, 0 = both wrong
                if isequal(preds, [0; 1])
                    acc_mat(vox_i, comboIdx) = 1;
                elseif isequal(preds, [0; 0]) || isequal(preds, [1; 1])
                    acc_mat(vox_i, comboIdx) = 0.5;
                else
                    acc_mat(vox_i, comboIdx) = 0;
                end

                comboIdx = comboIdx + 1;
            end
        end
    end

    % Compute mean accuracy per voxel (omit NaNs)
    acc_mean = mean(acc_mat, 2, 'omitnan');
end
