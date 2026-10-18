# ============================================================
# Cosine similarity to LOO centroid
# Bayesian BF01: equal variances + equal means
# 6-panel figure + console descriptives
# ============================================================

# --- Packages (run once, then comment out) ---
# install.packages(c("BayesFactor", "Rcpp", "dplyr", "tidyr", "ggplot2", "remotes", "this.path"))
# remotes::install_github("fdabl/bfvartest")

library(bfvartest)
library(BayesFactor)
library(dplyr)
library(tidyr)
library(ggplot2)

# --- Data ---
repo_root <- normalizePath(file.path(dirname(this.path::this.path()), "..", ".."))
out_dir   <- file.path(repo_root, "results", "text")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
df <- read.csv(file.path(repo_root, "data", "behavioral", "text", "semantic_analysis_results.csv"),
               stringsAsFactors = FALSE)

df <- df %>%
  mutate(
    group_lab = recode(group, rel = "Religious", sec = "Secular"),
    group_lab = factor(group_lab, levels = c("Religious", "Secular")),
    topic = case_when(
      startsWith(question, "h") ~ "Chametz",
      startsWith(question, "k") ~ "Kosher",
      startsWith(question, "n") ~ "Neutral"
    ),
    task  = ifelse(grepl("1$", question), "Description", "Association"),
    panel = factor(
      paste(topic, task, sep = " – "),
      levels = c(
        "Chametz – Description", "Chametz – Association",
        "Kosher – Description",  "Kosher – Association",
        "Neutral – Description", "Neutral – Association"
      )
    )
  )

# --- Per-question stats (once) ---
questions <- c("h1", "h2", "k1", "k2", "n1", "n2")

stats_tbl <- bind_rows(lapply(questions, function(q) {
  x  <- df$cosine_similarity[df$question == q & df$group == "sec"]  # Secular
  y  <- df$cosine_similarity[df$question == q & df$group == "rel"]  # Religious
  n1 <- length(x); n2 <- length(y)
  m1 <- mean(x);   m2 <- mean(y)
  s1 <- sd(x);     s2 <- sd(y)
  
  # Cohen's d (Sec − Rel)
  sp <- sqrt(((n1 - 1) * s1^2 + (n2 - 1) * s2^2) / (n1 + n2 - 2))
  d  <- (m1 - m2) / sp
  
  # Welch 95% CI for mean difference
  tt <- t.test(x, y, var.equal = FALSE)
  
  # BF01 equal means (JZS)
  bf01_mean <- 1 / as.vector(ttestBF(x = x, y = y, rscale = "medium"))
  
  # BF01 equal variances (bfvartest)
  bf01_var <- 1 / twosd_test(
    n1 = n1, n2 = n2, sd1 = s1, sd2 = s2,
    u = 0.5, log = FALSE
  )
  
  tibble(
    question  = q,
    panel     = unique(df$panel[df$question == q]),
    n_sec     = n1,  n_rel    = n2,
    mean_sec  = m1,  mean_rel = m2,
    sd_sec    = s1,  sd_rel   = s2,
    d         = d,
    ci_low    = unname(tt$conf.int[1]),
    ci_high   = unname(tt$conf.int[2]),
    BF01_mean = bf01_mean,
    BF01_var  = bf01_var,
    bf_label  = sprintf("BF[01] == %.2f", bf01_mean)
  )
}))

print(stats_tbl)

# --- 6-panel figure ---
p <- ggplot(df, aes(x = cosine_similarity, fill = group_lab, color = group_lab)) +
  geom_density(alpha = 0.45, linewidth = 0.8) +
  geom_rug(aes(color = group_lab),
           alpha = 0.45, length = unit(0.03, "npc"),
           show.legend = FALSE) +
  geom_vline(
    data = df %>%
      group_by(panel, group_lab) %>%
      summarise(m = mean(cosine_similarity), .groups = "drop"),
    aes(xintercept = m, color = group_lab),
    linetype = "dashed", linewidth = 0.5, alpha = 0.85,
    show.legend = FALSE
  ) +
  geom_text(
    data = stats_tbl,
    aes(x = Inf, y = Inf, label = bf_label),
    inherit.aes = FALSE,
    hjust = 1.08, vjust = 1.4,
    size = 3.2, parse = TRUE, color = "grey20"
  ) +
  facet_wrap(~ panel, ncol = 2, scales = "free_y") +
  scale_fill_manual(values  = c(Religious = "#FF9A8A", Secular = "#86aacc")) +
  scale_color_manual(values = c(Religious = "#f7705b", Secular = "#5b8dbb")) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(
    x = "Cosine similarity to LOO centroid",
    y = "Density",
    fill = NULL, color = NULL,
    title = "Cosine similarity to leave-one-out centroid",
    subtitle = "Religious vs. Secular, by topic and task"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position   = "bottom",
    strip.background  = element_rect(fill = "grey95", color = NA),
    strip.text        = element_text(face = "bold"),
    plot.title        = element_text(face = "bold"),
    panel.spacing     = unit(0.8, "lines")
  )

print(p)
# ggsave("cosine_loo_6panel.pdf", p, width = 9.5, height = 10, device = cairo_pdf)
ggsave(file.path(out_dir, "cosine_loo_6panel.svg"), p, width = 9.5, height = 10, dpi = 300)

# --- Console descriptives ---
fmt <- function(x, k = 3) formatC(x, digits = k, format = "f")

cat("\n============================================================\n")
cat("Descriptives per question × group (cosine similarity to LOO centroid)\n")
cat("============================================================\n\n")

for (i in seq_len(nrow(stats_tbl))) {
  r <- stats_tbl[i, ]
  
  cat(sprintf("— %s (%s)\n", r$panel, r$question))
  
  cat("  Secular:\n")
  cat(sprintf("    n    = %d\n", r$n_sec))
  cat(sprintf("    Mean = %s\n", fmt(r$mean_sec, 3)))
  cat(sprintf("    SD   = %s\n", fmt(r$sd_sec, 3)))
  
  cat("  Religious:\n")
  cat(sprintf("    n    = %d\n", r$n_rel))
  cat(sprintf("    Mean = %s\n", fmt(r$mean_rel, 3)))
  cat(sprintf("    SD   = %s\n", fmt(r$sd_rel, 3)))
  
  cat("  Comparison:\n")
  cat(sprintf("    BF01 equal means      = %s\n", fmt(r$BF01_mean, 3)))
  cat(sprintf("    BF01 equal variances  = %s\n", fmt(r$BF01_var, 3)))
  cat(sprintf("    Cohen's d (Sec − Rel) = %s\n", fmt(r$d, 3)))
  cat(sprintf("    95%% CI mean difference = [%s, %s]\n\n",
              fmt(r$ci_low, 3), fmt(r$ci_high, 3)))
}

# ============================================================
# --- Clean copy-paste blocks: each question, per video (no BF) ---
# One delimited block per question, grouped by video,
# so each can be copied into the doc separately.
# ============================================================

meta_tbl <- df %>% distinct(question, topic, task)

clean_tbl <- stats_tbl %>%
  select(question, n_sec, mean_sec, sd_sec,
         n_rel, mean_rel, sd_rel, d, ci_low, ci_high) %>%
  left_join(meta_tbl, by = "question") %>%
  arrange(match(question, questions))

rule <- strrep("-", 60)

for (v in c("Chametz", "Kosher", "Neutral")) {
  rows <- clean_tbl %>% filter(topic == v)

  cat("\n\n")
  cat("##############################################################\n")
  cat(sprintf("###  VIDEO: %s\n", toupper(v)))
  cat("##############################################################\n")

  for (i in seq_len(nrow(rows))) {
    r <- rows[i, ]

    cat("\n", rule, "\n", sep = "")
    cat(sprintf("%s — %s (%s)\n\n", v, r$task, r$question))
    cat(sprintf("Secular:    n = %d, M = %s, SD = %s\n",
                r$n_sec, fmt(r$mean_sec, 3), fmt(r$sd_sec, 3)))
    cat(sprintf("Religious:  n = %d, M = %s, SD = %s\n",
                r$n_rel, fmt(r$mean_rel, 3), fmt(r$sd_rel, 3)))
    cat(sprintf("Cohen's d (Sec − Rel) = %s\n", fmt(r$d, 3)))
    cat(sprintf("95%% CI mean difference = [%s, %s]\n",
                fmt(r$ci_low, 3), fmt(r$ci_high, 3)))
    cat(rule, "\n", sep = "")
  }
}
