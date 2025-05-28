# Null Distribution Generation

This folder contains the tools used to generate permutation-based null distributions for Within-Group ISC analyses.

---

## Contents

- **nullDist_W_ISC.m**  
  Core function that phase-scrambles group time-series data and computes ISC in a leave-one-out fashion, storing mean ISC values per permutation.

- **run_nullDist_W_ISC.m**  
  Example “driver” script for Linux VMs. It is written in a manner that allows running multiple sessions and iterate over groups/tasks.

---

## Computational Considerations

Generating these null distributions is **computationally intensive** (e.g. thousands of permutations × hundreds of thousands of voxels).  
In our work we used a Linux virtual machine and split the work across multiple consecutive sessions to run in parallel.

---

## Pre-generated Distributions

To avoid re-running this costly procedure, we provide pre-computed null distributions for all groups and tasks located in the matching OSF project.


After downloading, place the files into the corresponding folder:
```
religion-neuro-sync\data\fMRI\null_dist\isc
```

