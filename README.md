# In-group neural alignment serves as a biomarker of social identity

**Yohay Zvi¹\*, Nitai Kerem¹, Eldad Aviv² and Yaara Yeshurun¹²\***
¹ Sagol School of Neuroscience, ² School of Psychological Sciences, Tel Aviv University

Code and small data for the paper *In-group neural alignment serves as a biomarker of social identity* (PNAS, accepted; DOI pending).

Forty-two participants (21 religious, 21 secular) watched three short news and social-media videos in the fMRI scanner: a neutral one (Neutral, about the weather) and two about religion in public life (Kosher, Chametz). This repository takes the preprocessed fMRI data and the behavioral and text responses to every number and figure in the paper:

- within-group inter-subject correlation (ISC) and the Religious vs Secular comparison (Fig. 2A),
- synchronized voxels per brain network (Fig. 2B),
- a voxel-wise SVM that predicts group from ISC, with cluster-size correction (Fig. 2C),
- behavioral ratings and the text analyses (LIWC; semantic similarity) (Fig. 1, SI).

## Data

| What | Where |
|---|---|
| Raw fMRI (BIDS, defaced anatomicals) | OpenNeuro [ds008941](https://doi.org/10.18112/openneuro.ds008941.v1.0.0) |
| Preprocessed fMRI matrices, null distributions, stimuli | OSF [osf.io/a9xqj](https://osf.io/a9xqj/). Its `data/fMRI/` folder has the same layout as this repository's: download it into `data/fMRI/` (see [`data/README.md`](data/README.md)) |
| Behavioral ratings, text responses, LIWC features | this repository, `data/behavioral/` |

## Repository layout

```
config.m                    paths, names and every analysis parameter (edit only this, or config_local.m)
config_local_example.m      template for machine-specific paths
run_all_QA.m                runs steps 01-05 and checks every reported number
code/
  step01_within_group_ISC.m        ISC per group and video, phase-randomisation null, FDR
  step02_ISC_group_comparison.m    overlap/unique voxels, t-tests, proportion tests     -> Fig. 2A
  step03_network_proportions.m     Brainnetome / Yeo-17 networks, network tests        -> Fig. 2B
  step04_SVM_classification.m      leave-two-out SVM, label-shuffling null, clusters   -> Fig. 2C, Fig. S1
  step05_LIWC_group_differences.m  LIWC features, mean and variance tests              -> SI
  null_distributions/              code that generated the (large) null distributions
  text_analysis/                   semantic similarity (Python) and its statistics (R)  -> Fig. 1, SI
  figures/                         Fig. 1 (R), Fig. 2B (Python), Fig. S1 (MATLAB, run by step 04)
  utils/                           shared functions, Brainnetome atlas, NIfTI toolbox
data/
  behavioral/                      small CSVs used by steps 05, text_analysis and figures
  fMRI/                            kept_vox/ (reliable-voxel masks) and svm_accuracy/ are in git;
                                   the data matrices and null distributions come from OSF
results/
  behavioral/                      JASP reports: Mann-Whitney U and Levene tests on the ratings
                                   (everything else in results/ is written by the scripts)
```

## How to run

**Requirements.** MATLAB R2023b with the Statistics and Machine Learning and the Image Processing toolboxes (steps 01–05). Python 3 (`pip install -r code/requirements.txt`) and R (packages listed at the top of each R script) for the text analysis and figures.

1. **Get the data.** Download OSF's `data/fMRI/` folder into this repository's `data/fMRI/` and unzip `null_dist/svm/SVM.zip` in place ([`data/README.md`](data/README.md) lists every file). To keep the data elsewhere, point `config_local.m` to it.
2. **Run the neuroimaging pipeline and the checks.** In MATLAB, from the repository root:
   ```matlab
   run_all_QA
   ```
   This runs steps 01–05 and compares the outputs with every number reported in the paper and SI. It writes `results/qa_report.txt` (full log) and `results/qa_checks.csv` (one PASS/FAIL row per check). Each step can also be run on its own (`run code/step02_ISC_group_comparison.m`); it loads `config.m` itself.
3. **Text analysis.**
   ```bash
   python code/text_analysis/semantic_similarity.py      # optional: re-embeds the responses (downloads the model)
   Rscript code/text_analysis/semantic_similarity_stats.R
   ```
4. **Figures.**
   ```bash
   Rscript code/figures/fig1_behavior_and_text.R
   python  code/figures/fig2B_network_mirror_plot.py      # needs step 03
   ```
   Fig. 2A and Fig. 2C are brain maps: the NIfTI files written by step 02 (`results/group_comparison/nifti/`) and step 04 (`results/svm/nifti/SVM_<video>_final_*.nii`), shown on the cortical surface in Connectome Workbench.

### Computational notes

Three steps take days on a CPU and are **not** re-run by default. Their outputs from the original analysis are loaded instead (the SVM accuracies are in this repository, the null distributions on OSF). Each one is controlled by a switch in `config.m`, and the QA re-computes a sample of it:

| Step | Switch (`cfg.run.`) | Default | QA check |
|---|---|---|---|
| ISC null distributions (1,000 phase randomisations per group × video) | `iscNull` | load | — (random seed; a re-run is statistically equivalent, not identical) |
| SVM accuracies (leave-two-out, 441 folds per voxel) | `svmAccuracy` | load | 50 random voxels per video re-classified (`svmSpotCheck`) |
| SVM label-shuffling null (1,000 permutations per voxel) | `svmNull` | load | 10 random voxels × 1,000 permutations re-computed (`svmNullSpotCheck`) |

Null cluster sizes for the cluster correction are always computed from the SVM null (minutes).

A full QA run should take well under two hours; most of the time goes to loading the data matrices and to the spot checks.

## Notes on the methods

- **Video names.** The video called *Chametz* in the paper is `hammetz` in file names and code (`task-chametz` on OpenNeuro).
- **ISC threshold.** Voxels with mean within-group ISC above the phase-randomisation null at FDR q = 0.0005 (normal fit to the null, Benjamini–Hochberg).
- **SVM threshold.** Voxel-wise accuracy ≥ the 95th percentile of the pooled label-shuffling null (27/42 = 0.6429). The null fits the SVM on all 42 subjects and predicts the same subjects, so it is conservative compared with the cross-validated real accuracies.
- **Cluster-size correction.** Clusters are 6-connected voxels above the accuracy threshold. The minimum cluster size is the 99.356th percentile of the sizes of all clusters (of any size) in the 1,000 null maps, pooled (`code/utils/cluster_size_threshold.m`): 39 / 41 / 43 voxels for Neutral / Kosher / Chametz. The setting was chosen from a tuning grid (SI Fig. S1): excluding null clusters of size ≤ 0, 1, 2 or 3 voxels × ten percentiles between 95 and 99.9 (`cfg.svm.gridExclude`, `cfg.svm.gridPercentiles`); the paper uses no exclusion and the 99.356th percentile. Step 04 writes the full grid to `results/svm/cluster_size_tuning_grid.csv` and plots it (`results/svm/figS1_cluster_size_tuning_grid.png`); all 120 settings reproduce the original 2024 grid results exactly.
- **Clustering software.** The original analysis clustered with FSL (`cluster --connectivity=6`). MATLAB's `bwconncomp(…, 6)` gives identical clusters, on the real maps and on all 3 × 1,000 null maps, so FSL is not needed.
- **LIWC sample.** LIWC was run on English translations of the responses. The analysis uses the 21 + 21 scanned participants; `liwc_features.csv` also contains 6 Secular respondents who were not scanned (`in_fmri_sample = 0`).

## Citation

If you use this code or data, please cite the paper (see [`CITATION.cff`](CITATION.cff)).

## Credits

- NIfTI and ANALYZE toolbox, Jimmy Shen (`code/utils/nifti/NIFTI_tools`, BSD license in `license.txt`).
- Brainnetome atlas, Fan et al. 2016, *Cerebral Cortex*, [github.com/brainnetome/atlas](https://github.com/brainnetome/atlas); Yeo-7/17 network assignments from the same source.
- `fdr_BH.m`, C. Honey; `theoretic_pvalues.m`, after Tal Ohad; `prop_test.m`, MATLAB Central File Exchange #45966; `nullDist_W_ISC.m` based on code by C. J. Honey (2010).
- Semantic-similarity pipeline, Eldad Aviv; Hebrew model [MPA/sambert](https://huggingface.co/MPA/sambert).

## License

Code: MIT (see [`LICENSE`](LICENSE)).

## Contact

Yohay Zvi, yohayzvi@gmail.com
