# ISC Analysis

This folder contains scripts for conducting within-group Inter-Subject Correlation (ISC) analyses.

## Contents
- **within_group_ISC_analysis.m**: Main ISC driver script  
- **generate_null_dist/**: Scripts to (re)generate permutation-based null distributions
(previously generated null distribution can be found in the OSF platform)  


## Quick Start
1. **Clone and navigate**:
   ```bash
   git clone https://github.com/YohayZvi/religion-neuro-sync.git
   cd religion-neuro-sync/code/analysis/isc
   ```
2. **Prepare data**:  
   Download data files from the OSF platform and place your files under:
   ```
   data/fMRI/data_mat_combined/
   data/fMRI/kept_vox/
   data/fMRI/null_dist/isc/
   ```
3. **Run ISC**:  
   In MATLAB, simply execute:
   ```matlab
   within_group_ISC_analysis
   ```

## Outputs
- NIfTI maps: `results/isc/nifti/`  
- Summary `.mat` files: `results/isc/`

## Notes
- Ensure `MNI152_T1_2mm_brain.nii` is in `code/utils/nifti/`.  
- Paths are determined at runtime relative to the project root.


