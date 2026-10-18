% -------------------------------------------------------------------
% step04_SVM_classification.m
%
% Predicts group labels (Religious vs Secular) for each voxel based on ISC scores.
% Workflow:
%   1. Load within-group ISC values and significance masks
%   2. Select voxels significant in either group
%   3. Perform leave-two-out SVM classification per voxel
%      (by default the pre-computed accuracies are loaded and a random
%      sample of voxels is re-classified as a check; set
%      cfg.run.svmAccuracy = true to re-run all voxels)
%   4. Save accuracy matrices to results/svm/ (when re-run)
%   5. Convert mean accuracies into NIfTI maps under results/svm/nifti/
%   6. Threshold the accuracies at the 95th percentile of the
%      label-shuffling null distribution
%   7. Correct for multiple comparisons by cluster size (threshold chosen
%      from a tuning grid, Fig. S1) and save the final maps (Fig. 2C)
%
% Project: Religious-Dependent Neural Synchronization
% Author : Yohay Zvi
% Date   : May 9, 2024
% Checked: May 2025
% -------------------------------------------------------------------

if ~exist('cfg', 'var')
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    cfg = config();
end
outDir   = cfg.paths.out.svm;
niftiDir = fullfile(outDir, 'nifti');
if ~exist(niftiDir, 'dir'), mkdir(niftiDir); end
volSize = [91 109 91];   % 2 mm MNI grid, as in values_to_nifti

summary = table();
tuningGrid = table();                               % cluster-size tuning grid (Fig. S1)
fslNull = [];                                       % optional: null cluster sizes of the original FSL run (QA only)
if isfield(cfg, 'ref') && isfield(cfg.ref, 'fslClusters') && exist(cfg.ref.fslClusters, 'file')
    fslNull = load(cfg.ref.fslClusters).clusterMetaData;
end

for vi = 1:numel(cfg.videos)
    vid = cfg.videos(vi);
    fprintf('\n=== Step 04 | %s ===\n', vid);

    %% VOIs and ISC values (step 01)
    R = load(fullfile(cfg.paths.out.isc, sprintf('W_ISC_Religious_%s.mat', vid)), 'W_ISC_values', 'mean_ISC_within', 'sigindx');
    S = load(fullfile(cfg.paths.out.isc, sprintf('W_ISC_Secular_%s.mat',   vid)), 'W_ISC_values', 'mean_ISC_within', 'sigindx');
    sig_vox = logical(R.sigindx + S.sigindx);
    religious_isc = R.W_ISC_values(sig_vox, :);
    secular_isc   = S.W_ISC_values(sig_vox, :);
    % compared in single precision, as the original compared the saved (float32) mean-ISC maps
    religious_higher = single(R.mean_ISC_within(sig_vox)) > single(S.mean_ISC_within(sig_vox));
    secular_higher   = single(R.mean_ISC_within(sig_vox)) < single(S.mean_ISC_within(sig_vox));
    clear R S
    fprintf('  VOIs: %d\n', sum(sig_vox));

    [accSpotDiff, nullSpotDiff, fslSame] = deal(NaN);                    % QA values (NaN = not run)

    %% 1. accuracy per VOI
    if cfg.run.svmAccuracy
        [acc_mat, mean_acc] = SVM_L2out(religious_isc, secular_isc);   % hours
        save(fullfile(outDir, sprintf('SVM_2out_Religious_Secular_%s.mat', vid)), 'acc_mat', 'mean_acc', 'sig_vox');
    else
        P = load(fullfile(cfg.paths.svmAccuracy, sprintf('SVM_2out_Religious_Secular_%s.mat', vid)), 'mean_acc', 'sig_vox');
        assert(isequal(logical(P.sig_vox(:)), sig_vox(:)), 'Pre-computed SVM file was made on a different VOI set.');
        mean_acc = P.mean_acc;  clear P
        if cfg.run.svmSpotCheck > 0                                       % re-classify a random sample
            rng(1);  idx = sort(randperm(numel(mean_acc), cfg.run.svmSpotCheck));
            [~, check] = SVM_L2out(religious_isc(idx, :), secular_isc(idx, :));
            accSpotDiff = max(abs(check(:) - mean_acc(idx(:))));
            fprintf('  spot check: %d random VOIs, max |difference| = %.3g\n', numel(idx), accSpotDiff);
        end
    end
    keptVoxFile = fullfile(cfg.paths.keptVox, sprintf('unifyKeptVox_%s.mat', vid));
    accFull = zeros(size(sig_vox));  accFull(sig_vox) = mean_acc;
    values_to_nifti(accFull, cfg.mm, keptVoxFile, niftiDir, char("SVM_2out_Religious_Secular_" + vid), true);

    %% 2. voxel threshold from the label-shuffling null
    % Regenerating the null takes days per video, so by default the call is
    % skipped and the pre-computed null (OSF) is loaded; a few voxels are
    % re-computed instead to confirm the code reproduces it.
    if cfg.run.svmNull
        run_SVM_nullDist(cfg, vid);                                       % days; see the function header
    end
    N = load(fullfile(cfg.paths.nullSVM, sprintf('SVM_Religious_Secular_nullDist_%s.mat', vid)), 'nullDist_acc_mat');
    nullAcc = N.nullDist_acc_mat;  clear N
    assert(size(nullAcc, 1) == sum(sig_vox), 'SVM null was made on a different VOI set.');
    if ~cfg.run.svmNull && cfg.run.svmNullSpotCheck > 0                    % re-compute the null in a few VOIs
        rng(2);  idx = sort(randperm(size(nullAcc, 1), cfg.run.svmNullSpotCheck));
        check = SVM_class_nullDist(religious_isc(idx, :), secular_isc(idx, :), size(nullAcc, 2));
        nullSpotDiff = max(abs(check - nullAcc(idx, :)), [], 'all');
        fprintf('  null spot check: %d random VOIs x %d permutations, max |difference| = %.3g\n', ...
                numel(idx), size(nullAcc, 2), nullSpotDiff);
    end
    thrAcc = prctile(nullAcc(:), cfg.svm.nullPercentile);
    fprintf('  accuracy threshold (%dth percentile of null): %.4f\n', cfg.svm.nullPercentile, thrAcc);

    %% 3. clusters in the real map
    keptVox = load(keptVoxFile);  keptVox = logical(keptVox.(char(fieldnames(keptVox))));
    toVolume = @(v) reshape(local_expand(v, sig_vox, keptVox), volSize) ~= 0;
    realCC   = bwconncomp(toVolume(mean_acc >= thrAcc), cfg.svm.clusterConnectivity);
    realSize = cellfun(@numel, realCC.PixelIdxList);

    %% null cluster sizes (one vector per permutation)
    nullSizes = cell(size(nullAcc, 2), 1);
    for it = 1:size(nullAcc, 2)
        cc = bwconncomp(toVolume(nullAcc(:, it) >= thrAcc), cfg.svm.clusterConnectivity);
        nullSizes{it} = cellfun(@numel, cc.PixelIdxList)';
    end
    if ~isempty(fslNull)                                                 % compare with the original FSL run
        same = cellfun(@(a, b) isequal(sort(a(:)), sort(double(b(:)))), nullSizes, fslNull.(char(vid))(:));
        fslSame = mean(same);
        fprintf('  null clusters identical to the original FSL run in %d of %d permutations\n', sum(same), numel(same));
    end
    clear nullAcc

    %% 4. cluster-size threshold: tuning grid (Fig. S1) and the chosen setting
    % exclusion of small null clusters (size <= 0, 1, 2, 3) x 10 percentiles between 95 and 99.9
    for ex = cfg.svm.gridExclude
        for p = cfg.svm.gridPercentiles
            t    = cluster_size_threshold(nullSizes, ex, p);
            keep = realSize(realSize >= t);
            tuningGrid = [tuningGrid; table(vid, ex, p, t, numel(keep), sum(realSize < t), sum(keep), sum(realSize(realSize < t)), ...
                mean(keep), median(keep), std(keep), ...
                'VariableNames', {'task', 'exc_criteria', 'percentile_range', 'selected_thresh', 'numClustersAboveThresh', ...
                'numClustersExcluded', 'totalVoxelsKept', 'totalVoxelsExcluded', 'meanClusterSize', 'medianClusterSize', 'stdClusterSize'})]; %#ok<AGROW>
        end
    end
    thrSize = cluster_size_threshold(nullSizes, cfg.svm.clusterExclude, cfg.svm.clusterPercentile);

    %% 5. surviving voxels and final maps
    survivors = false(prod(volSize), 1);
    survivors(vertcat(realCC.PixelIdxList{realSize >= thrSize})) = true;
    keepVOI = survivors(local_voi_index(sig_vox, keptVox));               % back to VOI order
    nKeep = sum(keepVOI);  nRel = sum(keepVOI & religious_higher);  nSec = sum(keepVOI & secular_higher);
    fprintf('  min cluster size %.4g -> %d clusters, %d voxels (Religious > Secular: %d; Secular > Religious: %d)\n', ...
            thrSize, sum(realSize >= thrSize), nKeep, nRel, nSec);

    writeMap = @(mask, name) values_to_nifti(local_masked(accFull, sig_vox, mask), cfg.mm, keptVoxFile, niftiDir, char(name), true);
    writeMap(keepVOI,                    "SVM_" + vid + "_final_two_groups");
    writeMap(keepVOI & religious_higher, "SVM_" + vid + "_final_religious_over_secular");
    writeMap(keepVOI & secular_higher,   "SVM_" + vid + "_final_secular_over_religious");

    summary = [summary; table(vid, cfg.videoLabels(vi), sum(sig_vox), thrAcc, sum(mean_acc >= thrAcc), numel(realSize), ...
        thrSize, sum(realSize >= thrSize), nKeep, nRel, nSec, min(mean_acc(keepVOI)), max(mean_acc(keepVOI)), ...
        accSpotDiff, nullSpotDiff, fslSame, ...
        'VariableNames', {'video', 'label', 'VOIs', 'accuracy_threshold', 'voxels_above_threshold', 'clusters', ...
        'min_cluster_size', 'clusters_kept', 'predictive_voxels', 'religious_higher', 'secular_higher', 'min_accuracy', 'max_accuracy', ...
        'qa_accuracy_spotcheck_maxdiff', 'qa_null_spotcheck_maxdiff', 'qa_null_clusters_same_as_FSL'})]; %#ok<AGROW>
end

writetable(summary, fullfile(outDir, 'svm_summary.csv'));
writetable(tuningGrid, fullfile(outDir, 'cluster_size_tuning_grid.csv'));
run(fullfile(cfg.paths.code, 'figures', 'figS1_cluster_size_tuning_grid.m'));   % Fig. S1
disp(summary)
fprintf('Step 04 done. Results in %s\n', outDir);

%% ---- local functions ---------------------------------------------------
function full = local_expand(voiValues, sig_vox, keptVox)
% VOI vector -> full 902,629-voxel vector (as values_to_nifti does)
inKept = zeros(size(sig_vox));  inKept(sig_vox) = voiValues;
full = zeros(size(keptVox));    full(keptVox) = inKept;
end

function idx = local_voi_index(sig_vox, keptVox)
% linear index (in the full grid) of every VOI, in VOI order
keptIdx = find(keptVox);
idx = keptIdx(sig_vox);
end

function v = local_masked(accFull, sig_vox, keepVOI)
% accuracy values at surviving VOIs, zero elsewhere (vector over kept voxels)
v = zeros(size(accFull));
s = find(sig_vox);
v(s(keepVOI)) = accFull(s(keepVOI));
end
