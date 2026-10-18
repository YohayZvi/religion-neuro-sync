# ============================================================
# Figure 1 - Behavioral and text response variance
# ------------------------------------------------------------
#   LEFT  = behavioral ratings (9 measures x 3 videos): in-scanner VAS
#           (agreement, interest, emotional involvement; 0-100) and
#           post-scan emotion ratings (1-5, scaled x20 to 0-100)
#   RIGHT = text responses, cosine similarity to the leave-one-out
#           centroid (2 questions x 3 videos; semantic_similarity.py)
#
# Inputs  data/behavioral/vas_ratings_long.csv
#         data/behavioral/post_scan_emotion_ratings.csv
#         data/behavioral/text/semantic_analysis_results.csv
# Output  results/figures/fig1_behavior_and_text.svg
# Statistics for the behavioral ratings (Mann-Whitney U, Levene) were run
# in JASP; reports in results/behavioral/.
#
# Run     Rscript code/figures/fig1_behavior_and_text.R
#         R packages: ggplot2, dplyr, tidyr, patchwork, this.path
#
# Yohay Zvi, 2025-2026. Paths adapted to the repository, Oct 2026.
# ============================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)

# ----------------------------
# 0. PATHS (relative to this script)
# ----------------------------
repo_root <- normalizePath(file.path(dirname(this.path::this.path()), "..", ".."))
behav_dir <- file.path(repo_root, "data", "behavioral")
out_dir   <- file.path(repo_root, "results", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ----------------------------
# 1. SETUP & CONSTANTS
# ----------------------------
left_box_x    <- 0.65
right_box_x   <- 0.82
religious_col <- "tomato"
secular_col   <- "steelblue"

# Helper for error bars
boxplot_whiskers <- function(x) {
  s <- boxplot.stats(x)$stats
  data.frame(ymin = s[1], ymax = s[5])
}

# ----------------------------
# 2. DATA PROCESSING: VAS (0-100 Scale)
# ----------------------------
file_path_vas <- file.path(behav_dir, "vas_ratings_long.csv")
data_vas <- read.csv(file_path_vas, stringsAsFactors = FALSE)

df_vas <- data_vas %>%
  filter(group %in% c("Religious", "Secular")) %>%
  rename(measure = Question) %>%
  # Clean Video Names
  mutate(video = case_when(
    grepl("neut", video, ignore.case = TRUE) ~ "Neutral",
    grepl("kosh", video, ignore.case = TRUE) ~ "Kosher",
    grepl("metz", video, ignore.case = TRUE) ~ "Chametz", 
    TRUE ~ video
  )) %>%
  # Clean Measure Names (Broad regex to catch the missing 'Emotion' question)
  mutate(measure = case_when(
    grepl("agree",    measure, ignore.case = TRUE) ~ "Agreement",
    grepl("interest", measure, ignore.case = TRUE) ~ "Interest",
    # Catch 'involved', 'involvement', or just 'emotion' (if distinct from specific emotions)
    grepl("involv|emotion",   measure, ignore.case = TRUE) ~ "Emotional Involvement",
    TRUE ~ measure
  )) %>%
  select(group, video, measure, Rating)

# ----------------------------
# 3. DATA PROCESSING: EMOTIONS (1-5 Scale -> Scaled to 100)
# ----------------------------
file_path_emotions <- file.path(behav_dir, "post_scan_emotion_ratings.csv")
# fileEncoding: this CSV starts with a UTF-8 BOM, which otherwise turns
# the first column name into "X...ReligiousAffiliation"
data_emotions <- read.csv(file_path_emotions, stringsAsFactors = FALSE,
                          fileEncoding = "UTF-8-BOM")

df_emotions <- data_emotions %>%
  select(-matches("^ForOrAgainst")) %>%
  pivot_longer(
    cols      = -ReligiousAffiliation,
    names_to  = c("video", "measure"),
    names_sep = "\\.",
    values_to = "Rating"
  ) %>%
  rename(group = ReligiousAffiliation) %>%
  mutate(group = ifelse(tolower(group) == "religious", "Religious", "Secular")) %>%
  # Clean Video Names
  mutate(video = case_when(
    grepl("neut", video, ignore.case = TRUE) ~ "Neutral",
    grepl("kosh", video, ignore.case = TRUE) ~ "Kosher",
    grepl("metz", video, ignore.case = TRUE) ~ "Chametz",
    TRUE ~ video
  )) %>%
  # Clean Measure Names
  mutate(measure = case_when(
    grepl("happy",    measure, ignore.case = TRUE) ~ "Happiness",
    grepl("sad",      measure, ignore.case = TRUE) ~ "Sadness",
    grepl("fear",     measure, ignore.case = TRUE) ~ "Fear",
    grepl("disgust",  measure, ignore.case = TRUE) ~ "Disgust",
    grepl("anger",    measure, ignore.case = TRUE) ~ "Anger",
    grepl("surprise", measure, ignore.case = TRUE) ~ "Surprise",
    TRUE ~ measure
  )) %>%
  # *** SCALING STEP ***
  # Multiply 1-5 ratings by 20 to put them on the same 0-100 scale as VAS
  mutate(Rating = Rating * 20) %>%
  select(group, video, measure, Rating)

# ----------------------------
# 4. MERGE & ORDER
# ----------------------------
df_combined <- bind_rows(df_vas, df_emotions)

# Force Video Order
df_combined$video <- factor(df_combined$video, 
                            levels = c("Neutral", "Kosher", "Chametz"))

# Force Measure Order
# "General Emotion" represents the VAS question about emotional involvement
target_measures <- c(
  "Agreement", 
  "Interest", 
  "Emotional Involvement", 
  "Happiness", 
  "Sadness", 
  "Fear", 
  "Disgust", 
  "Anger", 
  "Surprise"
)

df_final <- df_combined %>%
  filter(measure %in% target_measures) %>%
  mutate(measure = factor(measure, levels = target_measures))

# ----------------------------
# 5. PLOTTING (behavioral block)
# ----------------------------
p_final <- ggplot(df_final) +
  # Jitter
  geom_jitter(
    data = filter(df_final, group == "Secular"),
    aes(x = left_box_x, y = Rating, color = group),
    width = 0.05, height = 0.05, size = 2, alpha = 0.6
  ) +
  geom_jitter(
    data = filter(df_final, group == "Religious"),
    aes(x = right_box_x, y = Rating, color = group),
    width = 0.05, height = 0.05, size = 2, alpha = 0.6
  ) +
  
  # Error Bars
  stat_summary(
    data = filter(df_final, group == "Secular"),
    aes(x = left_box_x, y = Rating),
    fun.data = boxplot_whiskers, geom = "errorbar", width = 0.05
  ) +
  stat_summary(
    data = filter(df_final, group == "Religious"),
    aes(x = right_box_x, y = Rating),
    fun.data = boxplot_whiskers, geom = "errorbar", width = 0.05
  ) +
  
  # Boxplots
  geom_boxplot(
    data = filter(df_final, group == "Secular"),
    aes(x = left_box_x, y = Rating, fill = group),
    width = 0.15, outlier.shape = NA, alpha = 0.7
  ) +
  geom_boxplot(
    data = filter(df_final, group == "Religious"),
    aes(x = right_box_x, y = Rating, fill = group),
    width = 0.15, outlier.shape = NA, alpha = 0.7
  ) +
  
  # Scales & Colors
  scale_fill_manual(values = c("Religious" = religious_col, "Secular" = secular_col)) +
  scale_color_manual(values = c("Religious" = religious_col, "Secular" = secular_col)) +
  scale_x_continuous(
    breaks = c(left_box_x, right_box_x),
    labels = c("Secular", "Religious")
  ) +
  
  # Single Y-axis for all (0-100)
  scale_y_continuous(
    limits = c(0, 105), 
    breaks = c(0, 20, 40, 60, 80, 100),
    # Optional: Add a secondary axis to show the original 1-5 scale
    sec.axis = sec_axis(~ . / 20, name = "Emotion Rating (1-5 Scale)")
  ) +
  
  labs(title = "Combined Ratings (Emotions Scaled to 0-100)", x = NULL, y = "VAS Rating (0-100)") +
  
  facet_grid(video ~ measure) +
  
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold", size = 10),
    # video row-strips are drawn once, on the far right of the TEXT block
    strip.text.y = element_blank()
  )

# ============================================================
# 6. TEXT RESPONSES: cosine similarity to LOO centroid
#    Overlapping histograms, one column per question type.
#
#    Built as TWO single-column plots rather than one 2-column facet:
#    facet_grid ties free scales to rows for y and columns for x, so a
#    per-COLUMN count scale is only reachable by splitting the plots.
#    Within each plot the 3 video rows share both x and y.
# ============================================================
df_text <- read.csv(file.path(behav_dir, "text", "semantic_analysis_results.csv"),
                    stringsAsFactors = FALSE) %>%
  mutate(
    group = recode(group, rel = "Religious", sec = "Secular"),
    video = case_when(
      grepl("^h", question) ~ "Chametz",
      grepl("^k", question) ~ "Kosher",
      grepl("^n", question) ~ "Neutral"
    ),
    measure = ifelse(grepl("1$", question), "Free description", "Word association")
  ) %>%
  mutate(
    video   = factor(video,   levels = c("Neutral", "Kosher", "Chametz")),
    measure = factor(measure, levels = c("Free description", "Word association"))
  ) %>%
  select(group, video, measure, Rating = cosine_similarity)

make_text_density <- function(meas, show_row_strip, plot_title = NULL,
                              y_lab = "Density") {
  d <- filter(df_text, measure == meas)

  means <- d %>%
    group_by(video, measure, group) %>%
    summarise(m = mean(Rating), .groups = "drop")

  ggplot(d, aes(x = Rating, fill = group, color = group)) +
    geom_density(alpha = 0.7, linewidth = 0.8) +
    geom_rug(aes(color = group),
             alpha = 0.45, length = unit(0.03, "npc"),
             show.legend = FALSE) +
    geom_vline(
      data = means,
      aes(xintercept = m, color = group, linetype = "Group mean"),
      linewidth = 0.5, alpha = 0.85
    ) +
    scale_fill_manual(values  = c("Religious" = religious_col, "Secular" = secular_col)) +
    scale_color_manual(values = c("Religious" = religious_col, "Secular" = secular_col)) +
    scale_linetype_manual(name = NULL, values = c("Group mean" = "dashed")) +
    # full cosine range, shared by both columns
    scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    labs(title = plot_title, x = NULL, y = y_lab) +
    # the behavioral block's legend already labels the two groups;
    # only the dashed-mean key is added here
    guides(
      fill     = "none",
      color    = "none",
      linetype = guide_legend(override.aes = list(color = "grey30", alpha = 1))
    ) +
    facet_grid(video ~ measure) +
    theme_minimal() +
    theme(
      panel.grid   = element_blank(),
      strip.text   = element_text(face = "bold", size = 10),
      # row strips drawn once, on the far right of the whole figure
      strip.text.y = if (show_row_strip) {
        element_text(face = "bold", size = 10)
      } else {
        element_blank()
      }
    )
}

p_desc  <- make_text_density("Free description", FALSE, "Text Responses")
# right column: y label dropped, the left column already names the axis
p_assoc <- make_text_density("Word association", TRUE,  NULL, y_lab = NULL)

# ----------------------------
# 7. COMBINE
#    An 11-column design: the behavioral block spans columns 1-9 and each
#    text column takes one, so every panel is the same physical width.
#    Row 1 holds all three plots (so their panels stay aligned); row 2 is a
#    thin strip holding one shared, centred x-axis label for the text block.
# ----------------------------
x_lab_text <- wrap_elements(
  grid::textGrob("Cosine similarity", gp = grid::gpar(fontsize = 11))
)

layout <- c(
  area(t = 1, l = 1,  b = 1, r = 9),    # p_final
  area(t = 1, l = 10, b = 1, r = 10),   # p_desc
  area(t = 1, l = 11, b = 1, r = 11),   # p_assoc
  area(t = 2, l = 10, b = 2, r = 11)    # centred x label, spanning both
)

p_all <- p_final + p_desc + p_assoc + x_lab_text +
  plot_layout(design = layout, heights = c(25, 1), guides = "collect")

print(p_all)

out_svg <- file.path(out_dir, "fig1_behavior_and_text.svg")
ggsave(out_svg, p_all, width = 20, height = 7.5, dpi = 300)

cat(sprintf("\nSaved: %s\n", out_svg))
