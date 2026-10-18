%% STEP 01 - Within-group inter-subject correlation (ISC)
% -------------------------------------------------------------------------
% Paper:    SI "In-Group Intersubject Correlation (ISC)"; Fig. 2A (input)
% Purpose:  For each group (Religious, Secular) and video, compute
%           leave-one-out ISC per voxel, test it against a phase-randomised
%           null distribution, and FDR-correct.
%           It performs the following stages:
%           (a) NaNs sanity check for the input data (`dataMat_combined`)
%           (b) Calls the W-ISC function to compute within-group ISC
%           (c) Loads pre-computed null distributions and computes p-values
%           (d) Applies FDR correction and saves thresholded NIfTI maps
%           (e) Saves ISC values and significance masks for each group/video
%
% Inputs  (see config.m for locations)
%   <Group>_Combined_task_<video>.mat   dataMat_combined: voxels x TRs x subjects
%   W_ISC_nullDist_<Group>_<video>.mat  nullDist: voxels x 1,000 permutations
%   unifyKeptVox_<video>.mat            voxel mask, used to write NIfTI maps
%
% Outputs (results/isc/)
%   W_ISC_<Group>_<video>.mat  W_ISC_values (voxels x subjects), mean_ISC_within,
%                              pvalues, pcrit, sigvals, sigindx, qcrit
%                              (sigindx / pcrit refer to q = 0.0005, the last
%                              value in cfg.isc.qcrits; used by steps 02-04)
%   nifti/mean_ISC_<Group>_<video>.nii                 unthresholded mean ISC
%   nifti/mean_ISC_<Group>_<video>_afterFDR_<q>.nii    mean ISC, FDR-thresholded
%
% Method
%   ISC: Pearson correlation of each subject's time course with the mean of
%   the other subjects of the same group (within_ISC_YZ_fast). P-values: a
%   normal distribution is fitted to each voxel's null (theoretic_pvalues),
%   right tail. FDR: Benjamini-Hochberg (fdr_BH).
%
% Run time: ~10-20 min (mostly loading the 2.7-3.3 GB matrices). MATLAB
%   R2023b + Statistics and Machine Learning Toolbox.
%
% Yohay Zvi. Original: July 2023 (within_group_ISC_main.m). Consolidated
% for the public repository, Oct 2026: paths and names only, logic unchanged.
% -------------------------------------------------------------------------

if ~exist('cfg', 'var')
    addpath(fileparts(fileparts(mfilename('fullpath'))));   % repository root
    cfg = config();
end
outDir   = cfg.paths.out.isc;
niftiDir = fullfile(outDir, 'nifti');
if ~exist(niftiDir, 'dir'), mkdir(niftiDir); end
printNaNs = true;   % print the NaN summary of each input matrix

%% (Optional) generate the ISC null distributions
% Heavy: 1,000 phase-randomised permutations per group and video (days on a
% workstation). The pre-computed nulls on OSF are loaded below instead. To
% regenerate them set cfg.run.iscNull = true; see
% code/null_distributions/run_nullDist_W_ISC.m for the original driver
% (it was split into several sessions run in parallel).
if cfg.run.iscNull
    run(fullfile(cfg.paths.code, 'null_distributions', 'run_nullDist_W_ISC.m'));
end

%% ISC per group and video
for gi = 1:numel(cfg.groups)
    for vi = 1:numel(cfg.videos)
        grp = cfg.groups(gi);
        vid = cfg.videos(vi);
        fprintf('\n=== Step 01 | %s | %s ===\n', grp, vid);

        % load the preprocessed data matrix
        S = load(fullfile(cfg.paths.dataMat, sprintf('%s_Combined_task_%s.mat', grp, vid)), 'dataMat_combined');
        dataMat_combined = S.dataMat_combined;  clear S

        % (a) NaNs sanity check (whole missing voxels are expected)
        quantify_nans(dataMat_combined, grp, vid, printNaNs);

        % (b) within-group ISC (leave-one-out)
        [mean_ISC_within, W_ISC_values] = within_ISC_YZ_fast(dataMat_combined);
        clear dataMat_combined

        % unthresholded map
        keptVoxFile = fullfile(cfg.paths.keptVox, sprintf('unifyKeptVox_%s.mat', vid));
        values_to_nifti(mean_ISC_within, cfg.mm, keptVoxFile, niftiDir, ...
                        char(sprintf('mean_ISC_%s_%s', grp, vid)), true);

        % (c) load the pre-computed null distribution and compute p-values
        N = load(fullfile(cfg.paths.nullISC, sprintf('W_ISC_nullDist_%s_%s.mat', grp, vid)), 'nullDist');
        pvalues = theoretic_pvalues(N.nullDist, mean_ISC_within);  clear N

        % (d) FDR correction and thresholded NIfTI maps (last q is kept for later steps)
        for qcrit = cfg.isc.qcrits
            [pcrit, sigvals, sigindx] = fdr_BH(pvalues, qcrit);
            above_thresh_W_ISC = mean_ISC_within;
            above_thresh_W_ISC(~sigindx) = 0;
            values_to_nifti(above_thresh_W_ISC, cfg.mm, keptVoxFile, niftiDir, ...
                            char(sprintf('mean_ISC_%s_%s_afterFDR_%.4f', grp, vid, qcrit)), true);
        end
        assert(qcrit == cfg.isc.qcritMain, 'The last FDR level must be the one used in the paper (%.4f).', cfg.isc.qcritMain);
        fprintf('  above threshold (q = %.4f): %d of %d voxels\n', qcrit, sum(sigindx), numel(sigindx));

        % (e) save ISC values and significance masks
        save(fullfile(outDir, sprintf('W_ISC_%s_%s.mat', grp, vid)), ...
             'W_ISC_values', 'mean_ISC_within', 'pvalues', 'pcrit', 'sigvals', 'sigindx', 'qcrit');
    end
end
fprintf('\nStep 01 done. Results in %s\n', outDir);
