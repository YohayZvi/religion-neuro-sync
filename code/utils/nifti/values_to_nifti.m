function values_to_nifti(to_be_transfered, mm, collective_keptVox_path, outputPath, savename, is_collectiv_keptVox_needed)
% -------------------------------------------------------------------
% values_to_nifti.m
%
% Maps a vector of voxel values into the MNI152 2 mm brain template
% and saves the result as a NIfTI file.
%
% Usage:
%   values_to_nifti(data_vec, mm, keptVoxPath, outputDir, saveName, useMask)
%
% Inputs:
%   data_vec     – numeric vector of voxel values (length = # kept voxels)
%   mm           – must be 2 (only 2 mm template supported)
%   keptVoxPath  – path to .mat file containing a logical mask vector
%   outputDir    – directory where the .nii file will be saved
%   saveName     – filename (without '.nii') for the output image
%   useMask      – logical; if true, expand data_vec into full brain volume
%
% Project: Religious-Dependent Neural Synchronization
% Author : unknown 
% Original Date : unknown
% Checked      : May 2025 (YZ)
% -------------------------------------------------------------------

% Validate `mm`
if mm ~= 2
    error('values_to_nifti:InvalidMM', 'Parameter mm must be 2 for the 2 mm template.');
end
matX = 91; matY = 109; matZ = 91;
 

% Determine this function’s path on disk
funcPath = mfilename('fullpath');
if isempty(funcPath)
    funcPath = which('values_to_nifti');
end
funcDir = fileparts(funcPath);  
% funcDir now points to .../religion-neuro-sync/code/utils/nifti

% Build the template path relative to that folder
templateFile = fullfile(funcDir, 'MNI152_T1_2mm_brain.nii');

% Error out if it’s missing
if ~exist(templateFile,'file')
    error('values_to_nifti:TemplateNotFound', ...
          'Expected template at %s', templateFile);
end

nii_temp = templateFile;

% load file of collective_keptVox
if is_collectiv_keptVox_needed == true
    collective_keptVox = load(collective_keptVox_path);
    name = fields(collective_keptVox);
    collective_keptVox = collective_keptVox.(name{1});
    collective_keptVox = logical(collective_keptVox); 

    to_be_viewed = zeros(size(collective_keptVox)); 
    to_be_viewed(collective_keptVox) = to_be_transfered; 
else
    to_be_viewed = to_be_transfered;
end


        to_be_viewed = reshape(to_be_viewed,[matX, matY, matZ]); % rehaspe vrom vector to brain

        % nii = load_nii(nii_temp);
        nii = load_untouch_nii(nii_temp);
 
        nii.hdr.dime.datatype = 16;
        nii.hdr.dime.bitpix = 32;
        nii.hdr.dime.cal_min=0.5;
        nii.hdr.dime.cal_max=0.8;

        %insert to_be_viewed into nii 
        nii.img = to_be_viewed;
        nii.img(isnan(nii.img)) = 0;

        %save nii
        save_untouch_nii(nii,fullfile(outputPath,strcat(savename, '.nii')));

