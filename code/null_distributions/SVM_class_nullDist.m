function acc_mat = SVM_class_nullDist(group1, group2, num_shuf)
% SVM_CLASS_NULLDIST  Null distribution of SVM accuracy by label shuffling.
%
%   acc_mat = SVM_class_nullDist(group1, group2, num_shuf)
%
% Inputs
%   group1, group2 - voxels x subjects (here: each subject's ISC value)
%   num_shuf       - number of label shufflings (the paper used 1,000)
%
% Output
%   acc_mat - voxels x num_shuf: accuracy (proportion of subjects
%             classified correctly) for each shuffling
%
% Purpose: threshold for the real (cross-validated) accuracies. In each
% shuffling the group labels are permuted, a linear SVM is fit on all
% subjects and used to predict the same subjects (no train/test split). The
% in-sample fit asks "how well can a linear boundary separate randomly
% assigned groups at best?", so the null is conservative.
%
% Yohay Zvi, May 2024. Header revised Oct 2026; code unchanged.

numVox = size(group1,1);
numSub1 = size(group1,2);
numSub2 = size(group2,2);
N = numSub1+numSub2;
labels = [zeros(numSub1,1); ones(numSub2,1)];
data = [group1 group2];
acc_mat = nan(numVox,num_shuf);
for iter_i = 1:num_shuf
    rng(iter_i + num_shuf, 'twister'); % use different seed each iteration
    labels = labels(randperm(N)); % shuffle labels randomly
    for vox_i = 1:numVox
        % fit model and test the accuracy using the same data
        SVM_model = fitcsvm(data(vox_i,:)',labels,'KernelFunction', 'linear');
        class = predict(SVM_model,data(vox_i,:)');
        % measure accuracy
        acc = sum (class == labels);
        acc_mat(vox_i, iter_i) = acc/N;
    end
end

end
