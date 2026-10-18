# Data

## `behavioral/` (in this repository)

| File | Content | Used by |
|---|---|---|
| `vas_ratings_long.csv` | In-scanner ratings after each video on a 0–100 visual analogue scale: agreement, interest, emotional involvement. One row per subject × video × question; columns `subject, group, video, Question, Rating`. Religious n = 19 (two participants have no in-scanner ratings), Secular n = 21. | Fig. 1 |
| `post_scan_emotion_ratings.csv` | Post-scan ratings (1–5) of six emotions (happy, sad, fear, disgust, anger, surprise) per video, plus the for/against item. One row per participant (21 + 21). | Fig. 1 |
| `text/data_final.csv` | Free-text answers in Hebrew, two per video: `1` = "describe what you saw", `2` = "what is the first thing that comes to mind" (word association). `question` = `n`/`k`/`h` (Neutral/Kosher/Chametz) + `1`/`2`; `group` = `rel`/`sec`. 21 + 21 scanned participants; no identifiers. | `semantic_similarity.py` |
| `text/semantic_analysis_results.csv` | The same responses with each one's cosine similarity to its group's leave-one-out centroid (the values used in the paper). | Fig. 1, `semantic_similarity_stats.R` |
| `text/liwc_features.csv` | LIWC2015 output (89 features) for the English translation of every response. `in_fmri_sample` = 1 for the 21 + 21 scanned participants; 0 for 6 Secular respondents who were not scanned. | step 05 |

Group statistics on the ratings (Mann–Whitney U, Levene) are in `results/behavioral/` (JASP reports).

## `fMRI/`

`kept_vox/` and `svm_accuracy/` are in this repository. Everything else comes from the OSF project [osf.io/a9xqj](https://osf.io/a9xqj/), whose `data/fMRI/` folder has the same layout: download it into this folder and unzip `null_dist/svm/SVM.zip` in place. To keep the data elsewhere, set `cfg.DATA_ROOT` in `config.m`, or override single paths in `config_local.m` (copy `config_local_example.m`).

```
data/fMRI/
├── data_mat_combined/   <Group>_Combined_task_<video>.mat           dataMat_combined: voxels × TRs × subjects   (OSF, ~3 GB each)
├── kept_vox/            unifyKeptVox_<video>.mat                     902,629 × 1 logical: reliable voxels         (this repository)
├── null_dist/
│   ├── isc/             W_ISC_nullDist_<Group>_<video>.mat           nullDist: reliable voxels × 1,000           (OSF, ~1.7 GB each)
│   └── svm/             SVM_Religious_Secular_nullDist_<video>.mat   nullDist_acc_mat: VOIs × 1,000              (OSF, in SVM.zip)
└── svm_accuracy/        SVM_2out_Religious_Secular_<video>.mat       mean_acc and sig_vox: accuracy per VOI      (this repository)
```

`<Group>` is `Religious` or `Secular`; `<video>` is `neutral`, `kosher` or `hammetz` (Chametz).

**What the matrices contain.** Preprocessed BOLD (FSL FEAT 6.00: skull stripping, slice-time and motion correction, high-pass filtering, 4 mm FWHM smoothing, normalisation to MNI 2 mm). Each voxel is z-scored within subject, and the time courses are aligned to the hemodynamic response (shift set from the A1+ peak response to the Neutral video). Only voxels with a reliable signal in at least 80% of the participants of each group are kept (`kept_vox`: 224,821 / 224,770 / 224,577 voxels for Neutral / Kosher / Chametz). Raw data and preprocessing inputs are on OpenNeuro ([ds008941](https://doi.org/10.18112/openneuro.ds008941.v1.0.0)).

**Rows.** The data matrices and ISC nulls have one row per reliable voxel (the `kept_vox` mask, MNI 2 mm grid). The SVM null and accuracy files have one row per voxel of interest (VOI): reliable voxels above the ISC threshold in either group (65,792 / 94,254 / 88,143), in the same order.
