%% RUN_ALL_QA - run the full neuroimaging pipeline and check it against the paper
% -------------------------------------------------------------------------
% Runs steps 01-05 in order (heavy null-distribution and full-SVM steps are
% skipped and their pre-computed outputs loaded; see config.m, cfg.run) and
% then checks every number reported in the paper/SI. If reference outputs
% from the original 2023-2024 analysis are available (cfg.ref, set in
% config_local.m), they are compared too.
%
% Output: results/qa_report.txt (full console log) and a PASS/FAIL table.
% Run time: roughly 30-60 min, dominated by loading the data matrices.
%
% Yohay Zvi, Oct 2026.
% -------------------------------------------------------------------------

clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(root);
cfg = config();
if ~exist(cfg.paths.results, 'dir'), mkdir(cfg.paths.results); end
logFile = fullfile(cfg.paths.results, 'qa_report.txt');
if exist(logFile, 'file'), delete(logFile); end
diary(logFile);
fprintf('QA run started %s\nMATLAB %s\n', string(datetime('now')), version);
t0 = tic;

%% Pipeline
run(fullfile(cfg.paths.code, 'step01_within_group_ISC.m'));
run(fullfile(cfg.paths.code, 'step02_ISC_group_comparison.m'));
run(fullfile(cfg.paths.code, 'step03_network_proportions.m'));
run(fullfile(cfg.paths.code, 'step04_SVM_classification.m'));
run(fullfile(cfg.paths.code, 'step05_LIWC_group_differences.m'));

%% Checks against the paper (Neutral / Kosher / Chametz)
checks = table('Size', [0 4], 'VariableTypes', {'string', 'string', 'string', 'logical'}, ...
               'VariableNames', {'check', 'expected', 'obtained', 'pass'});
add = @(T, name, e, o) [T; table(string(name), string(mat2str(e)), string(mat2str(o)), isequal(e, o), ...
                         'VariableNames', T.Properties.VariableNames)];

C = readtable(fullfile(cfg.paths.out.compare, 'voxel_counts.csv'));
checks = add(checks, 'Reliable voxels (SI)',               [224821 224770 224577], C.reliable_voxels');
checks = add(checks, 'VOIs (SI)',                          [65792 94254 88143],    C.VOIs');
checks = add(checks, 'Unique voxels, Religious (SI)',      [22693 32571 31716],    C.unique_to_religious');
checks = add(checks, 'Unique voxels, Secular (SI)',        [7413 8392 6337],       C.unique_to_secular');
checks = add(checks, 'Significant unique, Religious (SI)', [10375 11001 16579],    C.significant_after_ttest_FDR_religious');
checks = add(checks, 'Significant unique, Secular (SI)',   [1182 1442 1043],       C.significant_after_ttest_FDR_secular');

P = readtable(fullfile(cfg.paths.out.compare, 'proportion_tests.csv'));
checks = add(checks, 'All group proportion tests p < 0.001 (main text)', true, all(P.p_value < 0.001));

Tn = readtable(fullfile(cfg.paths.out.networks, 'network_proportion_tests.csv'), 'TextType', 'string');
u = Tn(Tn.test == "unique", :);
checks = add(checks, 'Religious higher in network comparisons (main text: 50 of 51)', [50 51], ...
             [sum(u.X1_Religious ./ u.N1 > u.X2_Secular ./ u.N2), height(u)]);

V = readtable(fullfile(cfg.paths.out.svm, 'svm_summary.csv'));
checks = add(checks, 'SVM accuracy threshold 0.6429 (SI)',   true, all(abs(V.accuracy_threshold - 27/42) < 1e-12));
checks = add(checks, 'Min cluster size (SI: 36, 41, 43*)',   [39 41 43],          round(V.min_cluster_size'));
checks = add(checks, 'Predictive voxels (SI)',               [7627 5653 9185],    V.predictive_voxels');
checks = add(checks, 'Religious > Secular voxels (SI)',      [7492 5442 9016],    V.religious_higher');
checks = add(checks, 'Secular > Religious voxels (SI)',      [135 211 169],       V.secular_higher');
checks = add(checks, 'Max accuracy 0.920 (main text)',       0.920,               round(max(V.max_accuracy), 3));
checks = add(checks, 'QA: SVM accuracy spot check reproduces stored values (max |diff| < 1e-12)', true, all(V.qa_accuracy_spotcheck_maxdiff < 1e-12));
checks = add(checks, 'QA: SVM null spot check reproduces stored null (max |diff| < 1e-12)',      true, all(V.qa_null_spotcheck_maxdiff < 1e-12));
if all(~isnan(V.qa_null_clusters_same_as_FSL))
    checks = add(checks, 'QA: null clusters (bwconncomp) identical to the original FSL run', true, all(V.qa_null_clusters_same_as_FSL == 1));
end

L = readtable(fullfile(cfg.paths.out.text, 'liwc_summary.csv'));
checks = add(checks, 'LIWC, fMRI sample: mean-diff cases/features, variance-diff cases/features, larger var Rel/Sec', ...
             [16 15 139 68 82 57], [L.mean_diff_cases L.mean_diff_features L.variance_diff_cases L.variance_diff_features L.larger_variance_religious L.larger_variance_secular]);
% the originally published LIWC numbers (27 Secular respondents, see step 05)
cfgMain = cfg;
cfg.liwc.fmriSampleOnly = false;  cfg.paths.out.text = fullfile(cfg.paths.results, 'text', 'liwc_27_secular');
run(fullfile(cfg.paths.code, 'step05_LIWC_group_differences.m'));
L = readtable(fullfile(cfg.paths.out.text, 'liwc_summary.csv'));
cfg = cfgMain;
checks = add(checks, 'LIWC, 27 Secular (as in submitted SI): 17/17, 113/64, 71/42', ...
             [17 17 113 64 71 42], [L.mean_diff_cases L.mean_diff_features L.variance_diff_cases L.variance_diff_features L.larger_variance_religious L.larger_variance_secular]);

%% Checks against the original outputs (if available)
if isfield(cfg, 'ref')
    for g = cfg.groups
        for v = cfg.videos
            new = load(fullfile(cfg.paths.out.isc, sprintf('W_ISC_%s_%s.mat', g, v)), 'mean_ISC_within', 'sigindx');
            old = load(fullfile(cfg.ref.iscResults,  sprintf('W_ISC_%s_%s.mat', g, v)), 'mean_ISC_within', 'sigindx');
            checks = add(checks, sprintf('ISC %s %s: max |diff| < 1e-10 and same significant voxels', g, v), true, ...
                         max(abs(new.mean_ISC_within - old.mean_ISC_within)) < 1e-10 && isequal(new.sigindx, old.sigindx));
        end
    end
    if isfield(cfg.ref, 'networksCsv') && exist(cfg.ref.networksCsv, 'file')
        A = readtable(fullfile(cfg.paths.out.networks, 'networks_division_and_wholeBrain.csv'), 'TextType', 'string');
        B = readtable(cfg.ref.networksCsv, 'TextType', 'string', 'VariableNamingRule', 'preserve');
        a = A{startsWith(A.Comparison, ["Unique", "Sig."]), 3:end};   % proportions only
        b = B{startsWith(strtrim(B.Comparison), ["Unique", "Sig."]), 3:end};
        % rows are sorted the same way in both files (Comparison, then Video)
        [~, ia] = sortrows([A.Comparison(startsWith(A.Comparison, ["Unique", "Sig."])), A.Video(startsWith(A.Comparison, ["Unique", "Sig."]))]);
        [~, ib] = sortrows(strtrim([B.Comparison(startsWith(strtrim(B.Comparison), ["Unique", "Sig."])), B.Video(startsWith(strtrim(B.Comparison), ["Unique", "Sig."]))]));
        checks = add(checks, 'Fig. 2B proportions equal the original figure table (max |diff| < 1e-6)', true, ...
                     max(abs(a(ia, :) - b(ib, :)), [], 'all') < 1e-6);
    end
    for vi = 1:numel(cfg.videos)
        v = cfg.videos(vi);
        f = fullfile(cfg.ref.svmCorrected, sprintf('Religious_Secular_SVM_ISC_acc_ClustersCorrected_%s_0_size_excluded_top99_3556_percentile.nii', v));
        if exist(f, 'file')
            old = niftiread(f) ~= 0;
            new = niftiread(fullfile(cfg.paths.out.svm, 'nifti', sprintf('SVM_%s_final_two_groups.nii', v))) ~= 0;
            checks = add(checks, sprintf('Fig. 2C map %s identical to the original corrected map', v), true, isequal(old, new));
        end
    end
end

%% Report
fprintf('\n================ QA SUMMARY ================\n');
disp(checks)
fprintf('%d of %d checks passed. (* SI states 36 for Neutral; see README.)\n', sum(checks.pass), height(checks));
writetable(checks, fullfile(cfg.paths.results, 'qa_checks.csv'));
fprintf('Total time: %.1f min\n', toc(t0) / 60);
diary off
