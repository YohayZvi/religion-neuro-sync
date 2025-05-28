# SVM Classification

This folder contains scripts for SVM‐based classification of voxelwise ISC scores between Religious and Secular groups.

---

## Scripts

- **SVM_L2out.m**  
  Performs Leave‐Two‐Out cross‐validation SVM per voxel, returning an accuracy matrix (`acc_mat`) and mean accuracy vector (`acc_mean`).

- **run_SVM_classification.m**  
  Driver script to load ISC data, call `SVM_L2out`, save results, and create NIfTI maps of mean accuracy.

- **SVM_class_nullDist**  

  Function to generate label‐shuffling null distributions (heavy computation). The `run` script is not provided due to potential differences in environments.
To generate the SVM distributions, call 'SVM_class_nullDist' with your group-wise ISC matrices 1,000 times per video. You can parallelize or split the job however you like.

The precomputed null distributions can be found in ```religion-neuro-sync\data\fMRI\null_dist\svm```
	

---

## Computational Considerations

- **Permutation load**: 21 subjects per group ⇒ 21×21 = 441 leave‐two‐out combinations per voxel.  
- **Runtime**: Expect multiple hours per video on a standard VM.

---

## Statistical Thresholding

We applied cluster‐size correction outside MATLAB using FSL’s `cluster` command:

1. **Initial threshold**: 95th percentile of each null distribution (0.6429).  
2. **Cluster extraction**: Generate NIfTI maps for each null iteration and feed them to FSL's `cluster` tool to derive cluster‐level statistics.

Full details are in the Methods section of the paper. **Note:** Code for the FSL cluster step is not provided here.

---





