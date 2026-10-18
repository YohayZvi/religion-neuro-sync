%% STEP 02 - Religious vs Secular: synchronized voxels, overlap/unique, t-tests
% -------------------------------------------------------------------------
% Paper:    Results "Neural Synchronization"; SI "Synchrony Masking and
%           Network Parcellation"; Fig. 2A
% Purpose:  Compare the two groups' within-group ISC maps from step 01:
%   (1) count voxels above the ISC threshold in each group and test the two
%       proportions (chi-square, no Yates correction);
%   (2) split the voxels of interest (VOIs: above threshold in either
%       group) into Overlap (both groups) and Unique (one group only);
%   (3) in each group's unique voxels, test whether that group's ISC is
%       higher than the other group's (one-tailed two-sample t-test per
%       voxel, FDR q = 0.05), and test the proportions again.
%
% Inputs   results/isc/W_ISC_<Group>_<video>.mat (step 01), keptVox masks
% Outputs  (results/group_comparison/)
%   secular_vs_religious_<video>.mat   masks: unique_religious, unique_secular,
%                                      overlap, sig_voxels_unique_religious,
%                                      sig_voxels_unique_secular (+ pcrit)
%   voxel_counts.csv                   one row per video (the numbers in the SI)
%   proportion_tests.csv               chi-square tests behind "all p < 0.001"
%   nifti/  unique_ISC_religious_compared_to_secular_<video>.nii
%           unique_ISC_secular_compared_to_religious_<video>.nii
%           overlap_ISC_religious_secular_<video>.nii
%           sig_voxels_unique_religious_compared_secular_afterFDR_<video>.nii   (Fig. 2A)
%           sig_voxels_unique_secular_compared_religious_afterFDR_<video>.nii   (Fig. 2A)
%
% Expected (SI): VOIs 65,792 / 94,254 / 88,143; unique 22,693 & 7,413 /
%   32,571 & 8,392 / 31,716 & 6,337; significant unique 10,375 & 1,182 /
%   11,001 & 1,442 / 16,579 & 1,043 (Neutral / Kosher / Chametz; Religious & Secular).
%
% Run time: a few minutes. MATLAB R2023b + Statistics and Machine Learning Toolbox.
%
% Yohay Zvi. Original: July 2023 (compare_religious_secular_main.m) and
% Sep 2024 (run_prop_test_all_comparisons.m, which read counts typed into a
% spreadsheet; here the counts are computed directly). Consolidated Oct 2026.
% -------------------------------------------------------------------------

if ~exist('cfg', 'var')
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    cfg = config();
end
inDir    = cfg.paths.out.isc;
outDir   = cfg.paths.out.compare;
niftiDir = fullfile(outDir, 'nifti');
if ~exist(niftiDir, 'dir'), mkdir(niftiDir); end

counts = table();   % one row per video
props  = table();   % one row per proportion test

for vi = 1:numel(cfg.videos)
    vid = cfg.videos(vi);
    fprintf('\n=== Step 02 | %s ===\n', vid);

    %% load both groups' ISC results (step 01)
    R = load(fullfile(inDir, sprintf('W_ISC_Religious_%s.mat', vid)), 'W_ISC_values', 'mean_ISC_within', 'sigindx');
    S = load(fullfile(inDir, sprintf('W_ISC_Secular_%s.mat',   vid)), 'W_ISC_values', 'mean_ISC_within', 'sigindx');
    religious_ISC = R.W_ISC_values;   mean_religious_ISC = R.mean_ISC_within;   religious_sigIdx = R.sigindx;
    secular_ISC   = S.W_ISC_values;   mean_secular_ISC   = S.mean_ISC_within;   secular_sigIdx   = S.sigindx;
    clear R S
    nReliable = numel(religious_sigIdx);   % voxels analysed (reliable in >= 80% of each group)

    %% unique and overlap voxels
    [unique_secular, unique_religious, overlap] = unique_overlap(secular_sigIdx, religious_sigIdx);

    %% one-tailed t-tests in unique voxels + FDR (q = 0.05, the function's default)
    [sig_voxels_unique_religious, ~, pcrit_religious] = unique_ttest(religious_ISC, secular_ISC, unique_religious, cfg.compare.ttestQ);
    [sig_voxels_unique_secular,   ~, pcrit_secular]   = unique_ttest(secular_ISC, religious_ISC, unique_secular, cfg.compare.ttestQ);

    %% counts (the SI numbers)
    row = table(vid, cfg.videoLabels(vi), nReliable, ...
        sum(religious_sigIdx), sum(secular_sigIdx), sum(religious_sigIdx | secular_sigIdx), sum(overlap), ...
        sum(unique_religious), sum(unique_secular), ...
        sum(sig_voxels_unique_religious), sum(sig_voxels_unique_secular), ...
        'VariableNames', {'video', 'label', 'reliable_voxels', ...
        'above_threshold_religious', 'above_threshold_secular', 'VOIs', 'overlap_voxels', ...
        'unique_to_religious', 'unique_to_secular', ...
        'significant_after_ttest_FDR_religious', 'significant_after_ttest_FDR_secular'});
    counts = [counts; row]; %#ok<AGROW>
    disp(row)

    %% proportion tests (chi-square, no Yates), as in the thesis/paper
    tests = { ...
        'voxels above W-ISC threshold',      [row.above_threshold_religious, row.above_threshold_secular], [nReliable, nReliable]; ...
        'unique voxels above W-ISC threshold', [row.unique_to_religious, row.unique_to_secular], [row.above_threshold_religious, row.above_threshold_secular]; ...
        'unique voxels significant after FDR', [row.significant_after_ttest_FDR_religious, row.significant_after_ttest_FDR_secular], [row.unique_to_religious, row.unique_to_secular]};
    for k = 1:size(tests, 1)
        X = tests{k, 2};  N = tests{k, 3};
        [h, p, chi2stat, df] = prop_test(X, N, cfg.compare.yates);
        props = [props; table(vid, string(tests{k, 1}), X(1), X(2), N(1), N(2), chi2stat, df, p, h, ...
            'VariableNames', {'video', 'comparison', 'Religious', 'Secular', 'N_Religious', 'N_Secular', 'chi2', 'df', 'p_value', 'h'})]; %#ok<AGROW>
    end

    %% save masks
    save(fullfile(outDir, sprintf('secular_vs_religious_%s.mat', vid)), ...
        'sig_voxels_unique_religious', 'sig_voxels_unique_secular', 'pcrit_religious', 'pcrit_secular', ...
        'unique_secular', 'unique_religious', 'overlap');

    %% brain maps
    keptVoxFile = fullfile(cfg.paths.keptVox, sprintf('unifyKeptVox_%s.mat', vid));
    m = mean_religious_ISC;  m(~unique_religious) = 0;
    values_to_nifti(m, cfg.mm, keptVoxFile, niftiDir, char("unique_ISC_religious_compared_to_secular_" + vid), true);
    m = mean_secular_ISC;    m(~unique_secular) = 0;
    values_to_nifti(m, cfg.mm, keptVoxFile, niftiDir, char("unique_ISC_secular_compared_to_religious_" + vid), true);
    values_to_nifti(overlap, cfg.mm, keptVoxFile, niftiDir, char("overlap_ISC_religious_secular_" + vid), true);
    m = mean_religious_ISC;  m(~sig_voxels_unique_religious) = 0;
    values_to_nifti(m, cfg.mm, keptVoxFile, niftiDir, char("sig_voxels_unique_religious_compared_secular_afterFDR_" + vid), true);
    m = mean_secular_ISC;    m(~sig_voxels_unique_secular) = 0;
    values_to_nifti(m, cfg.mm, keptVoxFile, niftiDir, char("sig_voxels_unique_secular_compared_religious_afterFDR_" + vid), true);
end

writetable(counts, fullfile(outDir, 'voxel_counts.csv'));
writetable(props,  fullfile(outDir, 'proportion_tests.csv'));
fprintf('\nStep 02 done. Results in %s\n', outDir);
