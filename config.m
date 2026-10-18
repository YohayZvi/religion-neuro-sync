function cfg = config()
% CONFIG  Single source of paths, names and analysis parameters.
%
% Every analysis script starts with `cfg = config();`, so this is the only
% file a user needs to edit.
%
% WHERE THE DATA GO
%   By default all large inputs are read from <repo>/data, laid out exactly
%   as on OSF (https://osf.io/a9xqj/):
%
%   data/
%   └── fMRI/
%       ├── data_mat_combined/   <Group>_Combined_task_<video>.mat   (voxels x TRs x subjects)
%       ├── kept_vox/            unifyKeptVox_<video>.mat             (902,629 x 1 logical; included in the repository)
%       ├── null_dist/
%       │   ├── isc/             W_ISC_nullDist_<Group>_<video>.mat   (voxels x 1,000)
%       │   └── svm/             SVM_Religious_Secular_nullDist_<video>.mat (VOI x 1,000; unzip SVM.zip here)
%       └── svm_accuracy/        SVM_2out_Religious_Secular_<video>.mat (pre-computed SVM accuracies; included in the repository)
%
%   To keep the data somewhere else, change DATA_ROOT below, or create a
%   file `config_local.m` next to this one (it is git-ignored; see
%   `config_local_example.m`) to override any individual path.
%
% NAMES
%   Code and file names use `hammetz` for the video called "Chametz" in the
%   paper (task-chametz on OpenNeuro). cfg.videoLabels holds the paper names.
%
% Yohay Zvi. Paths and parameters gathered from the original scripts, Oct 2026.

%% Repository root (this file's folder)
cfg.root = fileparts(mfilename('fullpath'));

%% Where the large inputs live (EDIT HERE, or use config_local.m)
cfg.DATA_ROOT = fullfile(cfg.root, 'data');

cfg.paths.dataMat      = fullfile(cfg.DATA_ROOT, 'fMRI', 'data_mat_combined');
cfg.paths.keptVox      = fullfile(cfg.DATA_ROOT, 'fMRI', 'kept_vox');
cfg.paths.nullISC      = fullfile(cfg.DATA_ROOT, 'fMRI', 'null_dist', 'isc');
cfg.paths.nullSVM      = fullfile(cfg.DATA_ROOT, 'fMRI', 'null_dist', 'svm');
cfg.paths.svmAccuracy  = fullfile(cfg.DATA_ROOT, 'fMRI', 'svm_accuracy');

%% Code and outputs (inside the repository)
cfg.paths.code    = fullfile(cfg.root, 'code');
cfg.paths.utils   = fullfile(cfg.root, 'code', 'utils');
cfg.paths.atlas   = fullfile(cfg.root, 'code', 'utils', 'atlas');
cfg.paths.results = fullfile(cfg.root, 'results');
cfg.paths.out.isc      = fullfile(cfg.paths.results, 'isc');
cfg.paths.out.compare  = fullfile(cfg.paths.results, 'group_comparison');
cfg.paths.out.networks = fullfile(cfg.paths.results, 'networks');
cfg.paths.out.svm      = fullfile(cfg.paths.results, 'svm');
cfg.paths.out.text     = fullfile(cfg.paths.results, 'text');

%% Small behavioral/text data shipped with the repository
cfg.paths.behavioral = fullfile(cfg.root, 'data', 'behavioral');

%% Study design
cfg.groups      = ["Religious", "Secular"];
cfg.videos      = ["neutral", "kosher", "hammetz"];   % file/code names
cfg.videoLabels = ["Neutral", "Kosher", "Chametz"];   % names used in the paper

%% Analysis parameters (values used in the paper)
cfg.mm = 2;                         % voxel size of the MNI template used for NIfTI output

% Step 01: within-group ISC
cfg.isc.qcrits    = [0.001, 0.0005];  % FDR levels written as maps (as in the original script)
cfg.isc.qcritMain = 0.0005;           % FDR level used in the paper and in all later steps

% Step 02: Religious vs Secular
cfg.compare.ttestQ    = 0.05;   % FDR q for the one-tailed t-tests in unique voxels
cfg.compare.yates     = false;  % chi-square proportion tests without Yates correction

% Step 03: networks
cfg.networks.bonferroniAlpha = 0.05;  % divided by the number of network tests

% Step 04: SVM classification
cfg.svm.nullPercentile     = 95;          % voxel threshold = 95th percentile of the pooled null (0.6429)
cfg.svm.clusterConnectivity = 6;          % face connectivity (same as FSL cluster --connectivity=6)
cfg.svm.gridExclude        = 0:3;                     % tuning grid (Fig. S1): ignore null clusters of size <= 0, 1, 2, 3
cfg.svm.gridPercentiles    = linspace(95, 99.9, 10);  %   x 10 percentiles of the null cluster-size distribution
cfg.svm.clusterExclude     = 0;                       % chosen: all null clusters counted
cfg.svm.clusterPercentile  = cfg.svm.gridPercentiles(9);  % chosen: 99.3556 (reported as 99.356)

% Step 05: LIWC
cfg.liwc.fmriSampleOnly = true;  % 21 + 21 scanned participants (false: also the 6 unscanned Secular respondents)

%% What to (re)compute. Heavy steps are OFF by default: their pre-computed
%% outputs are loaded instead (see README, "Computational notes").
cfg.run.iscNull        = false;  % ISC null distributions (phase randomisation, 1,000 perms)
cfg.run.svmAccuracy    = false;  % full leave-two-out SVM (hours per video)
cfg.run.svmSpotCheck   = 50;    % re-run the SVM on this many random voxels and compare (0 = skip)
cfg.run.svmNull        = false;  % SVM label-shuffling null (1,000 perms; days)
cfg.run.svmNullSpotCheck = 10;   % re-compute the null in this many random VOIs and compare (0 = skip)
% NOTE: with iscNull / svmNull = true the nulls are WRITTEN to
% cfg.paths.nullISC / nullSVM. Point those to a writable folder first.

%% Optional local overrides (git-ignored)
if exist(fullfile(cfg.root, 'config_local.m'), 'file')
    cfg = config_local(cfg);
end

%% Make code available
addpath(genpath(cfg.paths.utils));
addpath(fullfile(cfg.paths.code, 'null_distributions'));
end
