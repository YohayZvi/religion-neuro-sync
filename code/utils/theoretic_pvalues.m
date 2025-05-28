% -------------------------------------------------------------------
% theoretic_pvalues.m
%
% Computes right‐tail p‐values by fitting a normal distribution to each
% voxel’s permutation‐based null distribution.
%
% Inputs:
%   nulldist        – numeric matrix (voxels × permutations), null estimates
%   real_values     – numeric vector (voxels × 1), observed values (e.g., ISC)
%
% Output:
%   theoretic_pvalues – numeric vector (voxels × 1) of right‐tail p‐values
%
% Project: Religious‐Dependent Neural Synchronization
% Author : Tal Ohad (original)
% Checked: May 2025 (YZ)
% -------------------------------------------------------------------

function theoretic_pvalues = theoretic_pvalues(nulldist, real_values)

    % Validate that voxel counts match
    if size(nulldist, 1) ~= size(real_values, 1)
        error( ...
            'theoretic_pvalues:DimensionMismatch', ...
            'Number of voxels in nulldist (%d) must match length of real_values (%d).', ...
            size(nulldist,1), size(real_values,1) ...
        );
    end

    nVox = size(nulldist, 1);
    theoretic_pvalues = zeros(nVox, 1);

    % Fit normal distribution and compute right‐tail p‐value per voxel
    for v = 1:nVox
        [mu, sigma] = normfit(nulldist(v, :));
        p_lower = normcdf(real_values(v), mu, sigma);
        theoretic_pvalues(v) = 1 - p_lower;
    end

end
