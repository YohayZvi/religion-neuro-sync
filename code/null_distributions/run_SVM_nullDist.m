function run_SVM_nullDist(cfg, video, voxelRange)
% RUN_SVM_NULLDIST  Label-shuffling null distribution for the SVM accuracies (step 04).
%
%   run_SVM_nullDist(cfg, video)              all VOIs of one video, then combine
%   run_SVM_nullDist(cfg, video, [from to])   only VOIs from..to (one parallel session)
%
% Paper:   SI "Support Vector Machine (SVM) Classification": voxel threshold
%          = 95th percentile of this null (0.6429).
% Method:  SVM_class_nullDist.m - in every VOI, 1,000 times: shuffle the 42
%          group labels, fit a linear SVM on all subjects and predict the
%          same subjects (in-sample accuracy). Permutation k uses seed
%          rng(k + 1000), so every voxel sees the same 1,000 label sets.
% Inputs:  results/isc/W_ISC_<Group>_<video>.mat (step 01)
% Outputs: cfg.paths.nullSVM/chunks/SVM_2out_Religious_Secular_nullDist_<video>_voxels_<a>_<b>.mat
%              acc_mat: (b-a+1) x 1,000, saved every 5,000 VOIs
%          cfg.paths.nullSVM/SVM_Religious_Secular_nullDist_<video>.mat
%              nullDist_acc_mat: VOI x 1,000 (written by combine_SVM_nullDist
%              once all VOIs of the video are done)
%
% It writes to cfg.paths.nullSVM, so point that path to a writable folder
% first (config_local.m), never to the original data.
%
% Run time: days per video. The three nulls used in the paper are on OSF;
% by default step 04 loads them.
%
% How the paper's nulls were made (May 2024): the same function, run in two
% parallel MATLAB sessions per video, each saving portions of 5,000 VOIs
% (SVM_class_NullDist_<video>1/2.m), then combined with
% Combine_SVM_nullDist.m. The splits were:
%   neutral  VOIs 1-32,895  and 32,896-65,792
%   kosher   VOIs 1-47,126  and 47,127-94,254
%   hammetz  VOIs 1-44,071  and 44,072-88,143
% Because every portion restarts the same seeded label sequence, the split
% does not change the result.
%
% Yohay Zvi. Original: May 2024. Consolidated Oct 2026.

nPerm   = 1000;   % permutations
portion = 5000;   % VOIs per saved file
chunkDir = fullfile(cfg.paths.nullSVM, 'chunks');
if ~exist(chunkDir, 'dir'), mkdir(chunkDir); end

% VOIs and their ISC values, exactly as in step 04
R = load(fullfile(cfg.paths.out.isc, sprintf('W_ISC_Religious_%s.mat', video)), 'W_ISC_values', 'sigindx');
S = load(fullfile(cfg.paths.out.isc, sprintf('W_ISC_Secular_%s.mat',   video)), 'W_ISC_values', 'sigindx');
sig_vox = logical(R.sigindx + S.sigindx);
religious_isc = R.W_ISC_values(sig_vox, :);
secular_isc   = S.W_ISC_values(sig_vox, :);
clear R S
nVOI = size(religious_isc, 1);

if nargin < 3 || isempty(voxelRange), voxelRange = [1 nVOI]; end
starts = voxelRange(1):portion:voxelRange(2);
fprintf('SVM null | %s | VOIs %d-%d of %d | %d permutations\n', video, voxelRange(1), voxelRange(2), nVOI, nPerm);
for a = starts
    b = min(a + portion - 1, voxelRange(2));
    t = tic;
    acc_mat = SVM_class_nullDist(religious_isc(a:b, :), secular_isc(a:b, :), nPerm);
    save(fullfile(chunkDir, sprintf('SVM_2out_Religious_Secular_nullDist_%s_voxels_%d_%d.mat', video, a, b)), 'acc_mat');
    fprintf('  VOIs %d-%d saved (%.1f h)\n', a, b, toc(t) / 3600);
end

if isequal(voxelRange, [1 nVOI])
    combine_SVM_nullDist(chunkDir, cfg.paths.nullSVM, video, nVOI);
else
    fprintf('Partial run. When all sessions are done: combine_SVM_nullDist(''%s'', ''%s'', "%s", %d)\n', ...
            chunkDir, cfg.paths.nullSVM, video, nVOI);
end
end
