%% RUN_NULLDIST_W_ISC - null distributions for the within-group ISC (step 01)
% -------------------------------------------------------------------------
% Paper:    SI "Inter-Subject Correlation (ISC)": significance of each
%           voxel's mean within-group ISC against a phase-randomisation null.
% Purpose:  For every group and video, build a null distribution of mean
%           leave-one-out ISC with 1,000 phase randomisations
%           (nullDist_W_ISC.m -> phase_shuf_group_data.m).
%
% Inputs   cfg.paths.dataMat/<Group>_Combined_task_<video>.mat  (voxels x TRs x subjects)
% Outputs  cfg.paths.nullISC/W_ISC_nullDist_<Group>_<video>.mat
%              nullDist: voxels x 1,000 (mean ISC per permutation)
%
% Called by step01_within_group_ISC.m when cfg.run.iscNull = true, or run
% on its own. It writes to cfg.paths.nullISC, so point that path to a
% writable folder first (config_local.m), never to the original data.
%
% Run time: days per group x video on a CPU server (each permutation
%   correlates ~225,000 voxels x 21 subjects). The six nulls used in the
%   paper (~1.7 GB each) are on OSF; by default step 01 loads them.
%
% How the paper's nulls were made (June-July 2023): the same two functions,
% run on a Linux server in several parallel sessions per group x video
% (driver copies run_nullDist_W_ISC_1/_2/_3.m, each with its own iteration
% count; short "top-up" runs were added until every file had 1,000
% permutations). The partial files were then concatenated column-wise on
% Windows into the files above (July 2023). The random seed was set with
% rng('shuffle'), so a re-run gives a statistically equivalent, not an
% identical, null.
%
% Yohay Zvi. Original: June 2023. Consolidated Oct 2026.
% -------------------------------------------------------------------------

if ~exist('cfg', 'var')
    addpath(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    cfg = config();
end
nPerm = 1000;
if ~exist(cfg.paths.nullISC, 'dir'), mkdir(cfg.paths.nullISC); end

for vid = cfg.videos
    for grp = cfg.groups
        t = tic;
        fprintf('ISC null | %s | %s | %d permutations\n', grp, vid, nPerm);
        S = load(fullfile(cfg.paths.dataMat, sprintf('%s_Combined_task_%s.mat', grp, vid)), 'dataMat_combined');
        nullDist_W_ISC(S.dataMat_combined, nPerm, cfg.paths.nullISC, sprintf('W_ISC_nullDist_%s_%s', grp, vid));
        clear S
        fprintf('  done in %.1f h\n', toc(t) / 3600);
    end
end
