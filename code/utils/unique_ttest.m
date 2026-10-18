function [sig_voxels, p_values, pcrit, sigvals, sigindx] = unique_ttest (higher_group_data,second_group_data, mask, alpha)
% This function is used to compare between two groups ISC scores.
%
% It computes the difference in the ISC score for each unique voxel (i.e.,
% voxels that were above ISC threshold in one group but not in ther other).
%
% INPUT:
% higher_group_data - ISC scores of the group of the unique voxels mask
% second_group_data - ISC scores of the second group
% mask - logical mask for the unique voxels
% alpha = the input for the FDR correction
%
% OUTPUT:
% sig_voxels - logical mask of unique voxels, in the input dim
% p_values - p-values before FDR correction
% pcrit, sigvals, sigindx - based on the FDR correction function
% 
% Yohay Zvi, July 2023
%%
if nargin == 3
    alpha = 0.05; % use 0.05 as default qcrit
end
% perform t-test over the unique voxels
numUniqueVox = sum(mask);
p_values = nan(numUniqueVox,1);
sig_voxels = zeros(size(mask));
group1_masked = higher_group_data(mask,:);
group2_masked = second_group_data(mask,:);

for vox_ind = 1:numUniqueVox
    % test if the group with the above threshold ISC score is higher than the second group 
    [~, p_values(vox_ind)] = ttest2(group1_masked(vox_ind,:), group2_masked(vox_ind,:), "Tail","right"); 
end

[pcrit, sigvals, sigindx] = fdr_BH (p_values, alpha);
sig_voxels(mask) =  sigindx;  
sig_voxels = logical(sig_voxels);
end