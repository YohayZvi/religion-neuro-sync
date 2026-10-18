function cfg = config_local(cfg)
% CONFIG_LOCAL  Machine-specific overrides for config.m (example).
%
% Copy this file to `config_local.m` (git-ignored) and edit. config.m calls
% it automatically if it exists. Use it to point to data kept outside the
% repository, e.g. on another drive, without editing config.m. Only the
% paths you set here change; everything else comes from config.m.

DATA = 'D:\path\to\fMRI';   % <-- the folder holding the files downloaded from OSF

cfg.paths.dataMat      = fullfile(DATA, 'data_mat_combined');
cfg.paths.keptVox      = fullfile(DATA, 'kept_vox');
cfg.paths.nullISC      = fullfile(DATA, 'null_dist', 'isc');
cfg.paths.nullSVM      = fullfile(DATA, 'null_dist', 'svm');
cfg.paths.svmAccuracy  = fullfile(DATA, 'svm_accuracy');

% Optional: reference outputs of the original analysis (2023-2024). If set,
% run_all_QA.m also checks that the code reproduces them exactly.
% cfg.ref.iscResults   = '...';   % folder with W_ISC_<Group>_<video>.mat
% cfg.ref.svmCorrected = '...';   % folder with the cluster-corrected SVM maps
% cfg.ref.networksCsv  = '...';   % networks_division_and_wholeBrain.csv (Fig. 2B table)
% cfg.ref.fslClusters  = '...';   % nullDistClustersMetaData_allTesks.mat (null cluster sizes from FSL)
end
