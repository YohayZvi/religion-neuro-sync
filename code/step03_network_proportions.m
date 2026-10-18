%% STEP 03 - Synchronized voxels per brain network (Brainnetome / Yeo-17)
% -------------------------------------------------------------------------
% Paper:    Results "Neural Synchronization" ("50 of 51 network
%           comparisons"); SI "Synchrony Masking and Network Parcellation";
%           Fig. 2B
% Purpose:  Map the step-02 voxel sets onto the 17 Yeo networks via the
%           Brainnetome atlas (246 regions) and express each as a proportion
%           of the network's size. Then compare Religious vs Secular per
%           network with chi-square proportion tests (Bonferroni-corrected).
%
% Inputs   results/group_comparison/nifti/*.nii (step 02)
%          code/utils/atlas/BNA_subregions_YZ.mat  (region table: hemisphere,
%              gyrus, Yeo-7 / Yeo-17 network; adapted from
%              https://github.com/brainnetome/atlas)
%          code/utils/atlas/BN_atlas_vector.mat    (region label of every
%              voxel of the 2 mm MNI grid; BNA-maxprob-thr0-2mm)
% Outputs  (results/networks/)
%   xlsx/<map>_voxels_summary.xlsx      per map: counts and proportions per
%                                       region, gyrus, Yeo-7 and Yeo-17 network
%   networks_division_and_wholeBrain.csv input of code/figures/fig2B_mirror_plot.py
%   network_proportion_tests.csv        102 tests (3 videos x 17 networks x 2)
%
% Proportion = voxels of the map inside a network / voxels of that network
% in the atlas (network sizes from Nifti_BNA_Analysis_prop.m).
% Tests, per video and network:
%   unique:      unique Religious vs unique Secular voxels, N = network size
%   significant: significant vs unique voxels, within each group
% "50 of 51": in 50 of the 51 (17 x 3) "unique" comparisons the Religious
% proportion is higher; printed at the end.
%
% Run time: < 1 min. MATLAB R2023b + Statistics and Machine Learning
%   Toolbox + Image Processing Toolbox (niftiread).
%
% Yohay Zvi. Original: Aug 2024 (Nifti_BNA_Analysis_prop.m,
% figures_BNA_analysis.m), Mar 2025 (networks_divison_secular_religious_prop.m;
% the table it read was assembled by hand, here it is computed). Consolidated Oct 2026.
% -------------------------------------------------------------------------

if ~exist('cfg', 'var')
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    cfg = config();
end
inDir   = fullfile(cfg.paths.out.compare, 'nifti');
outDir  = cfg.paths.out.networks;
xlsDir  = fullfile(outDir, 'xlsx');
if ~exist(xlsDir, 'dir'), mkdir(xlsDir); end
atlasTable  = fullfile(cfg.paths.atlas, 'BNA_subregions_YZ.mat');
atlasVector = fullfile(cfg.paths.atlas, 'BN_atlas_vector.mat');

% the four voxel sets of Fig. 2B (map file prefix -> row name in the figure CSV)
maps = { ...
    'unique_ISC_religious_compared_to_secular_',                 'Unique Religious',                              'unique', 1; ...
    'unique_ISC_secular_compared_to_religious_',                 'Unique Secular',                                'unique', 2; ...
    'sig_voxels_unique_religious_compared_secular_afterFDR_',    'Sig. voxels after t-test and FDR in Religious', 'sig',    1; ...
    'sig_voxels_unique_secular_compared_religious_afterFDR_',    'Sig. voxels after t-test and FDR in Secular',   'sig',    2};

figRows = table();   % proportions for Fig. 2B
tests   = table();   % proportion tests

for vi = 1:numel(cfg.videos)
    vid = cfg.videos(vi);  lab = cfg.videoLabels(vi);
    fprintf('\n=== Step 03 | %s ===\n', vid);
    cnt = struct();
    for k = 1:size(maps, 1)
        name = [maps{k, 1}, char(vid)];
        net17 = Nifti_BNA_Analysis_prop(fullfile(inDir, [name '.nii']), atlasTable, atlasVector, ...
                                        fullfile(xlsDir, name));
        [netNames, keep] = clean_network_names(net17.Network17);
        net17 = net17(keep, :);
        cnt.(maps{k, 3})(:, maps{k, 4}) = net17.VoxelCount;
        cnt.size = net17.SizeInAtlas;                             % network sizes used for the proportions
        row = array2table(net17.Proportion', 'VariableNames', cellstr(netNames));
        row = [table(string(maps{k, 2}), lab, 'VariableNames', {'Comparison', 'Video'}), row]; %#ok<AGROW>
        figRows = [figRows; row]; %#ok<AGROW>
    end

    % proportion tests (chi-square, no Yates), as in networks_divison_secular_religious_prop.m
    for n = 1:numel(netNames)
        X = cnt.unique(n, :);  N = [cnt.size(n), cnt.size(n)];
        [h, p] = prop_test(X, N, false);
        tests = [tests; table(lab, netNames(n), "unique", X(1), X(2), N(1), N(2), p, h, ...
            'VariableNames', {'Video', 'Network', 'test', 'X1_Religious', 'X2_Secular', 'N1', 'N2', 'p_value', 'h_uncorrected'})]; %#ok<AGROW>
    end
    for n = 1:numel(netNames)
        X = cnt.sig(n, :);  N = cnt.unique(n, :);
        [h, p] = prop_test(X, N, false);
        tests = [tests; table(lab, netNames(n), "significant", X(1), X(2), N(1), N(2), p, h, ...
            'VariableNames', {'Video', 'Network', 'test', 'X1_Religious', 'X2_Secular', 'N1', 'N2', 'p_value', 'h_uncorrected'})]; %#ok<AGROW>
    end
end

%% Bonferroni over all network tests (102 = 3 videos x 17 networks x 2 tests)
alpha = cfg.networks.bonferroniAlpha / height(tests);
tests.sig_after_Bonferroni = tests.p_value < alpha;
writetable(tests, fullfile(outDir, 'network_proportion_tests.csv'));

%% Figure CSV: proportions + whole-brain counts (counts go in the first network column, as read by the plotting script)
C = readtable(fullfile(cfg.paths.out.compare, 'voxel_counts.csv'), 'TextType', 'string');
countRows = table();
for vi = 1:numel(cfg.videos)
    r = C(C.video == cfg.videos(vi), :);
    vals = {'number of unique religious', r.unique_to_religious; 'number of unique secular', r.unique_to_secular; ...
            'number of sig. religious', r.significant_after_ttest_FDR_religious; 'number of sig. secular', r.significant_after_ttest_FDR_secular};
    for k = 1:size(vals, 1)
        x = nan(1, width(figRows) - 2);  x(1) = vals{k, 2};
        countRows = [countRows; [table(string(vals{k, 1}), cfg.videoLabels(vi), 'VariableNames', {'Comparison', 'Video'}), ...
                                 array2table(x, 'VariableNames', figRows.Properties.VariableNames(3:end))]]; %#ok<AGROW>
    end
end
writetable([figRows; countRows], fullfile(outDir, 'networks_division_and_wholeBrain.csv'));

%% Summary line used in the paper
u = tests(tests.test == "unique", :);
fprintf('\nReligious proportion higher in %d of %d network comparisons (unique voxels).\n', ...
        sum(u.X1_Religious ./ u.N1 > u.X2_Secular ./ u.N2), height(u));
fprintf('Significant after Bonferroni (alpha = %.2g): %d of %d tests.\n', alpha, sum(tests.sig_after_Bonferroni), height(tests));
fprintf('Step 03 done. Results in %s\n', outDir);

%% ---- local functions ---------------------------------------------------
function [names, keep] = clean_network_names(raw)
% Display names for the 17 Yeo networks; drops the atlas category for
% regions without a Yeo-17 network (subcortical/unassigned). Errors if the
% atlas does not yield exactly 17 networks, so a mismatch cannot go unnoticed.
raw  = string(raw);
keep = ~(raw == "0" | raw == "" | contains(lower(raw), ["subcort", "none", "unknown", "unassigned"]));
n = strtrim(regexprep(raw(keep), '\s*\(.*\)', ''));       % "Default D (auditory)" -> "Default D"
n = regexprep(n, 'Limbix', 'Limbic');                      % typo in the atlas table
n = regexprep(n, '[-_]', ' ');
n = regexprep(n, '(^|\s)(\w)', '$1${upper($2)}');          % capitalise words
n = regexprep(n, 'Somato Motor', 'Somatomotor');
names = n;
if numel(names) ~= 17
    error('Expected 17 Yeo networks, found %d: %s', numel(names), strjoin(raw, ' | '));
end
end
