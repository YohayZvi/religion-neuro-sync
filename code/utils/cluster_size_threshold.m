function [thr, pooled] = cluster_size_threshold(nullClusterSizes, excludeSize, percentile)
% CLUSTER_SIZE_THRESHOLD  Minimum cluster size from a null distribution of clusters.
%
%   thr = cluster_size_threshold(nullClusterSizes, excludeSize, percentile)
%
% Inputs
%   nullClusterSizes - cell array (one cell per permutation) of vectors with
%                      the sizes (voxels) of all clusters found in that
%                      permutation's thresholded map
%   excludeSize      - null clusters of size <= excludeSize are ignored
%                      (0 = keep all; the paper used 0)
%   percentile       - percentile of the pooled null cluster sizes
%                      (the paper used 99.3556)
%
% Output
%   thr    - minimum cluster size; real clusters with size >= thr are kept
%   pooled - the pooled null cluster sizes used
%
% Method: all clusters of all permutations are pooled into one distribution
% and the threshold is MATLAB's prctile of it. (Note: this is the pooled
% cluster-size distribution, not the distribution of the largest cluster per
% permutation.)
%
% Reconstructed Oct 2026. The original script (cluster_size_correction_main_5,
% June 2024) was lost; this rule reproduces all 120 stored results of its
% tuning grid exactly (3 videos x 4 exclusion rules x 10 percentiles:
% thresholds, clusters kept and voxels kept).

pooled = cellfun(@(c) c(:), nullClusterSizes(:), 'UniformOutput', false);
pooled = vertcat(pooled{:});
pooled = double(pooled(pooled > excludeSize));
thr = prctile(pooled, percentile);
end
