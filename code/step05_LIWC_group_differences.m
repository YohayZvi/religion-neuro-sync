%% -----------------------------------------------------------------------
% LIWC Analysis: Religious vs Secular Group Comparisons
% Description:
% Compares LIWC outputs from religious and secular groups across tasks
% and question types (Welch t-test for means, Levene's test for
% variances; participants of the fMRI sample). Saves the test results
% and their summary (results/text/liwc_tests.csv, liwc_summary.csv).
% -----------------------------------------------------------------------

if ~exist('cfg', 'var')
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    cfg = config();
end
outDir = cfg.paths.out.text;
if ~exist(outDir, 'dir'), mkdir(outDir); end

T = readtable(fullfile(cfg.paths.behavioral, 'text', 'liwc_features.csv'), ...
              'TextType', 'string', 'VariableNamingRule', 'preserve');
if cfg.liwc.fmriSampleOnly
    T = T(T.in_fmri_sample == 1, :);
end
features = T.Properties.VariableNames(6:end);          % the 89 LIWC features
assert(numel(features) == 89, 'Expected 89 LIWC features, found %d.', numel(features));

tests = table();
for vid = cfg.videos
    for q = ["description", "association"]
        R = T(T.group == "Religious" & T.video == vid & T.question == q, :);
        S = T(T.group == "Secular"   & T.video == vid & T.question == q, :);
        for f = string(features)
            x = R.(f);  y = S.(f);
            [~, p, ~, st] = ttest2(x, y, 'Vartype', 'unequal');
            lev = vartestn([x; y], [repmat({'Religious'}, numel(x), 1); repmat({'Secular'}, numel(y), 1)], ...
                           'TestType', 'LeveneAbsolute', 'Display', 'off');
            larger = "Secular";  if std(x) > std(y), larger = "Religious"; end
            tests = [tests; table(vid, q, f, numel(x), numel(y), mean(x), mean(y), std(x), std(y), st.tstat, p, lev, larger, ...
                'VariableNames', {'video', 'question', 'feature', 'n_religious', 'n_secular', 'mean_religious', 'mean_secular', ...
                                  'sd_religious', 'sd_secular', 't', 'p_ttest', 'p_levene', 'larger_sd'})]; %#ok<AGROW>
        end
    end
end
writetable(tests, fullfile(outDir, 'liwc_tests.csv'));

%% Counts reported in the SI (p < .05, uncorrected, as in the original)
meanSig = tests.p_ttest  < 0.05;
varSig  = tests.p_levene < 0.05;
perFeature = groupsummary(tests(meanSig, :), 'feature');
summary = table(height(tests), numel(features), ...
    sum(meanSig), numel(unique(tests.feature(meanSig))), max([0; perFeature.GroupCount]), ...
    sum(varSig),  numel(unique(tests.feature(varSig))), ...
    sum(varSig & tests.larger_sd == "Religious"), sum(varSig & tests.larger_sd == "Secular"), ...
    'VariableNames', {'tests', 'features', 'mean_diff_cases', 'mean_diff_features', 'max_conditions_per_feature', ...
                      'variance_diff_cases', 'variance_diff_features', 'larger_variance_religious', 'larger_variance_secular'});
writetable(summary, fullfile(outDir, 'liwc_summary.csv'));
fprintf('\nLIWC (n = %d Religious, %d Secular per condition):\n', tests.n_religious(1), tests.n_secular(1));
disp(summary)
fprintf('Step 05 done. Results in %s\n', outDir);
