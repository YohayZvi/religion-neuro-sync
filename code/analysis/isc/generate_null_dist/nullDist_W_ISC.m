function nullDist_W_ISC(dataMat_combined, numScram, output_path, fileName)
% -------------------------------------------------------------------
% nullDist_W_ISC.m
%
% Generates a null distribution for within-group Inter-Subject
% Correlation (ISC) analysis via phase randomization.
%
% For each iteration:
%   1. Scramble group time series using phase_shuf_group_data
%   2. Compute ISC per voxel in a leave-one-out manner
%   3. Store mean ISC across subjects into the 'nullDist' matrix
%   4. Save progress incrementally to a .mat file via matfile interface
%
% Usage:
%   nullDist_W_ISC(dataMat_combined, numScram, output_path, fileName)
%
% Inputs:
%   dataMat_combined – numeric 3D array (voxels × TRs × subjects)
%   numScram         – integer, number of scrambling iterations
%   output_path      – string, directory to save the .mat file
%   fileName         – string, name of the .mat file to create/update
%
% Output:
%   A .mat file at fullfile(output_path, fileName) containing:
%     nullDist – matrix (voxels × numScram) of ISC values
%
% Author:          Yohay Zvi
% Based on code by: CJ Honey (April 2010)
% Original Date:   June 2023
% Checked:         May 2025
% -------------------------------------------------------------------

% Prepare save file
fullSaveName = validateName(fileName,output_path);
[numNodes, ~ , numSubs] = size (dataMat_combined);
mf = matfile (fullSaveName, "Writable",true); % create an updating matfile
mf.nullDist = nan (numNodes, numScram); % initialize var
% Initialize random seed
rng ('shuffle')

% Permute data for phase randomization (time × subs × voxels)
shuffled_data = permute (dataMat_combined, [2 3 1]);

% Main scrambling loop
for scram_ind = 1:numScram
    iter_start_time = tic;
    w_isc = nan(numNodes,numSubs);
    % Phase-scramble the data
    shuffled_data = real(phase_shuf_group_data(shuffled_data));
    shuffled_data = permute (shuffled_data, [3 1 2]); % premute back to Nodes x TRs x Subs
    % Compute ISC for each subject and voxel
    for sub_ind = 1:numSubs
        sub_intact = dataMat_combined(:,:,sub_ind);
        group_wo_sub = shuffled_data;
        group_wo_sub(:,:,sub_ind) = [];
        mean_group_wo_sub = mean(group_wo_sub,3,'omitnan');
        for node_ind = 1:numNodes
            w_isc(node_ind,sub_ind) = corr(mean_group_wo_sub(node_ind,:)', sub_intact(node_ind,:)',"rows","complete");
        end
    end

    % Store the mean ISC values for this iteration
    mf.nullDist(:,scram_ind) = mean(w_isc,2,'omitnan');

    % Restore data orientation for next iteration
    shuffled_data = permute (shuffled_data, [2 3 1]); % premute back (TRs x subs x Nodes)

    % display progress
    iter_end_time = toc (iter_start_time);
    estimated_finish = ((numScram-scram_ind)*iter_end_time)/(60);
    msg = sprintf ("Just finished iteration number %d (out of %d).\nLapse time - %.2f Seconds.\nEstimated time to finish: %.3f minutes (%.2f hours).\n\n",...,
        scram_ind, numScram, iter_end_time, estimated_finish, estimated_finish/60);
    disp (msg)
end
end

