% visualization of tuning grid for cluster size correction (Fig. S1)
%
% Top row: the minimum cluster size selected by each setting. Bottom row: the
% number of clusters in the real accuracy map at or above that size. One
% line per exclusion criterion (null clusters of size <= 0, 1, 2 or 3 ignored),
% x = percentile of the null cluster-size distribution (10 values, 95-99.9).
% The paper uses exclusion 0 and the 99.356 percentile.
%
% Input : results/svm/cluster_size_tuning_grid.csv (written by step 04)
% Output: results/svm/figS1_cluster_size_tuning_grid.png
% Called at the end of step04_SVM_classification.m; can also be run alone.
%
% Based on cluster_size_threshold_tuning_grid_visualization.m (Yohay Zvi,
% Sept 2024), which plotted the stored grid results (CorrectionSummaryResults).

if ~exist('cfg', 'var')
    addpath(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    cfg = config();
end
G = readtable(fullfile(cfg.paths.out.svm, 'cluster_size_tuning_grid.csv'), 'TextType', 'string');
tasks = cfg.videos;
num_tasks = numel(tasks);
fig = figure('Color', 'w', 'Position', [100 100 1200 800]);

for task_idx = 1:num_tasks
    task_data = G(G.task == tasks(task_idx), :);
    unique_exc_criteria = unique(task_data.exc_criteria);
    colors = lines(numel(unique_exc_criteria));

    % ---- top: selected threshold ----
    subplot(2, num_tasks, task_idx);  hold on;
    for crit_idx = 1:numel(unique_exc_criteria)
        filtered_data = task_data(task_data.exc_criteria == unique_exc_criteria(crit_idx), :);
        plot(filtered_data.percentile_range, filtered_data.selected_thresh, '-o', 'LineWidth', 2, 'Color', colors(crit_idx, :), ...
             'DisplayName', sprintf('Exclusion Criteria: %d', unique_exc_criteria(crit_idx)));
    end
    title(cfg.videoLabels(task_idx));
    xlabel('Percentile Range');  ylabel('Selected Threshold');
    legend('show', 'Location', 'northeast');  hold off;

    % ---- bottom: number of clusters above threshold ----
    subplot(2, num_tasks, task_idx + num_tasks);  hold on;
    for crit_idx = 1:numel(unique_exc_criteria)
        filtered_data = task_data(task_data.exc_criteria == unique_exc_criteria(crit_idx), :);
        plot(filtered_data.percentile_range, filtered_data.numClustersAboveThresh, '-o', 'LineWidth', 2, 'Color', colors(crit_idx, :), ...
             'DisplayName', sprintf('Exclusion Criteria: %d', unique_exc_criteria(crit_idx)));
    end
    xlabel('Percentile Range');  ylabel('Number of Clusters Above Threshold');
    legend('show', 'Location', 'northeast');  hold off;
end

exportgraphics(fig, fullfile(cfg.paths.out.svm, 'figS1_cluster_size_tuning_grid.png'), 'Resolution', 300);
close(fig);
clear G tasks num_tasks fig task_idx task_data unique_exc_criteria colors crit_idx filtered_data
