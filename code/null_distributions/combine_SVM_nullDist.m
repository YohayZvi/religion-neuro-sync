function nullDist_acc_mat = combine_SVM_nullDist(chunkDir, outDir, video, nVOI)
% COMBINE_SVM_NULLDIST  Join the partial SVM null files of one video.
%
%   combine_SVM_nullDist(chunkDir, outDir, video, nVOI)
%
% Reads chunkDir/SVM_2out_Religious_Secular_nullDist_<video>_voxels_<a>_<b>.mat
% (acc_mat, written by run_SVM_nullDist.m), places each block at rows a..b
% and saves outDir/SVM_Religious_Secular_nullDist_<video>.mat with
% nullDist_acc_mat (VOI x permutations). Errors if any VOI is missing.
%
% Yohay Zvi. Original: May 2024 (Combine_SVM_nullDist.m). Revised Oct 2026.

files = dir(fullfile(chunkDir, sprintf('SVM_2out_Religious_Secular_nullDist_%s_voxels_*.mat', video)));
nullDist_acc_mat = [];
done = false(nVOI, 1);
for f = files'
    tok = regexp(f.name, '_voxels_(\d+)_(\d+)\.mat$', 'tokens', 'once');
    a = str2double(tok{1});  b = str2double(tok{2});
    acc_mat = load(fullfile(f.folder, f.name)).acc_mat;
    if isempty(nullDist_acc_mat), nullDist_acc_mat = nan(nVOI, size(acc_mat, 2)); end
    nullDist_acc_mat(a:b, :) = acc_mat;
    done(a:b) = true;
end
if ~all(done)
    error('combine_SVM_nullDist: %d of %d VOIs of %s have no null yet.', sum(~done), nVOI, video);
end
save(fullfile(outDir, sprintf('SVM_Religious_Secular_nullDist_%s.mat', video)), 'nullDist_acc_mat');
fprintf('Combined %d files -> SVM_Religious_Secular_nullDist_%s.mat (%d x %d)\n', numel(files), video, size(nullDist_acc_mat));
end
