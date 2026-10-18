function [uniqueG1,uniqueG2, overlap] = unique_overlap (group1_idx,group2_idx)
% Extract the voxels that oveerlap between the groups or that are unique to one group and not the other. 
% 
% INPUT:
% group_idx - logical vector, voxel x 1, with significant voxels indices in
% the group, based on some analysis. 
%
% OUTPUT:
% uniqueG - logical mask of unique voxels to one of the groups
% overlap - logical mask of overlap voxels in both groups
%
% Yohay Zvi, July 2023
%% 
overlap = logical(group1_idx.*group2_idx);
uniqueG1 = group1_idx;
uniqueG1(group2_idx~=0) = 0;
uniqueG2 = group2_idx;
uniqueG2(group1_idx~=0) = 0;
end