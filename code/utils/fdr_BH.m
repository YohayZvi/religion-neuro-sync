function [pcrit, sigvals, sigindx] = fdr_BH(pvals, qcrit)

% implements the Benjamini-Hochberg procedure 
% for controlling the False Discovery Rate
%
% INPUTS:
%
%   pvals = [m by 1] vector of p-values
%   qcrit = critival value, q*, of the variable q (default q* = 0.05)
%
% OUTPUTS:
%
%   pcrit = the critical p-value
%   sigvals = the pvalues exceeding the critical p-value
%   sigindx = indices of input "pvals" where values exceed qcrit
%
% v 0.1 C Honey

if nargin < 2; qcrit = 0.05; end
if sum(pvals == 0) > 0; fprintf('Some p-values are identically zero. Check inputs!\n'); end

pvals = pvals(:);

m = length(pvals);
ps = sort(pvals, 'ascend');

thresh = [1:m]'/m*qcrit;

sigvals = ps(ps <= thresh);

if ~isempty(sigvals)
    pcrit = sigvals(end);
    sigindx = pvals <= pcrit;
else
    pcrit = NaN;
    sigindx = false(m,1);
end








