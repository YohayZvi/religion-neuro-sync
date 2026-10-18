function [net17, net7, gyri, regions] = Nifti_BNA_Analysis_prop(NiftiFilePath, atlasPath, atlasVecPath, outputName)
% NIFTI_BNA_ANALYSIS_PROP  Count the voxels of a brain map per Brainnetome
% region, gyrus and Yeo-7 / Yeo-17 network, as a proportion of their size.
%
%   [net17, net7, gyri, regions] = Nifti_BNA_Analysis_prop(NiftiFilePath, atlasPath, atlasVecPath, outputName)
%
% Inputs
%   NiftiFilePath - path to a NIfTI map on the 2 mm MNI grid (91x109x91).
%                   Every non-zero voxel counts (the map is binarised; no
%                   threshold is applied).
%   atlasPath     - path to BNA_subregions_YZ.mat: a table with one row per
%                   Brainnetome region (246) - hemisphere, gyrus, Yeo-7 and
%                   Yeo-17 network, and SizeInAtlas (voxels of the region in
%                   BNA-maxprob-thr0-2mm.nii). Adapted from
%                   https://github.com/brainnetome/atlas.
%   atlasVecPath  - path to BN_atlas_vector.mat: region label (1-246, 0 =
%                   outside the atlas) of every voxel of the 2 mm grid.
%   outputName    - (optional) path + file stem; if given, the four tables
%                   are written to <outputName>_voxels_summary.xlsx.
%
% Outputs (tables)
%   net17   - one row per Yeo-17 network (plus the atlas category "0" for
%             regions without a Yeo network): Network17, VoxelCount, Right,
%             Left, SizeInAtlas, Proportion (= VoxelCount / SizeInAtlas)
%   net7    - the same for the Yeo-7 networks (Network7, ...)
%   gyri    - the same per gyrus (Gyrus_full, ...)
%   regions - the atlas table plus voxelCountInData and Prop per region
%
% Changes from the August 2024 version (results are identical):
%   * returns the tables (the original only wrote a spreadsheet);
%   * network/gyrus sizes are summed from the atlas table's SizeInAtlas
%     column instead of hard-coded lists (the hard-coded values were
%     checked and are equal to these sums, network by network);
%   * rows are matched by exact name.
%
% Yohay Zvi, August 2024. Revised Oct 2026.

% Load atlas
BN_t = load(atlasPath).BNAsubregionsYZ;
BN_v = double(load(atlasVecPath).BN_atlas_vec);

% Load map, binarise, label each voxel with its atlas region
data = niftiread(NiftiFilePath);
data = data(:) ~= 0 & ~isnan(data(:));
labels = data .* BN_v(:);

% Voxels per region
numRegions = height(BN_t);
BN_t.voxelCountInData = arrayfun(@(i) sum(labels == i), (1:numRegions)');
BN_t.Prop = BN_t.voxelCountInData ./ BN_t.SizeInAtlas;

% Summaries per gyrus / network
right = string(BN_t.Hemisphere) == "Right";
left  = string(BN_t.Hemisphere) == "Left";
gyri  = summarise(string(BN_t.Gyrus_full),    'Gyrus_full');
net7  = summarise(string(BN_t.networName_7),  'Network7');
net17 = summarise(string(BN_t.networName_17), 'Network17');
regions = BN_t;

% Optional spreadsheet
if nargin > 3 && strlength(string(outputName)) > 0
    f = strcat(outputName, "_voxels_summary.xlsx");
    writetable(regions, f, 'Sheet', 'numVoxPerRegion');
    writetable(gyri,    f, 'Sheet', 'summaryGyri');
    writetable(net7,    f, 'Sheet', 'summaryNetwork7');
    writetable(net17,   f, 'Sheet', 'summaryNetwork17');
end

    function T = summarise(group, name)
        g = strtrim(group);
        names = unique(g);
        n = numel(names);
        [cnt, r, l, sz] = deal(zeros(n, 1));
        for k = 1:n
            idx = g == names(k);
            cnt(k) = sum(BN_t.voxelCountInData(idx));
            r(k)   = sum(BN_t.voxelCountInData(idx & right));
            l(k)   = sum(BN_t.voxelCountInData(idx & left));
            sz(k)  = sum(BN_t.SizeInAtlas(idx));
        end
        T = table(names, cnt, r, l, sz, cnt ./ sz, ...
                  'VariableNames', {name, 'VoxelCount', 'Right', 'Left', 'SizeInAtlas', 'Proportion'});
    end
end
