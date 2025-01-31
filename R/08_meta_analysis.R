# -----------------------------------------------------------------------------
#
# Conduct meta analysis on extracted effect sizes, by calculating 
# weighted (by sample size) mean/median effect sizes reported at CHI
# grouped by experiment design and topics
# This script produces csv-files as output which contain the summary stats.
#
# -----------------------------------------------------------------------------
library(tidyverse)
library(datawizard) # for weighted means
library(lares) # for tukey outliers
library(modi) # for weighted quantiles
source("00_utility_functions.R")


general_data_path <- file.path("..", "Data")
clean_data_path <- file.path(general_data_path, "R_clean_data")

df <- read.csv(file.path(clean_data_path, "unified_manualPlausibilitychecked_factorduplicatesremoved_2019-23.csv")) %>%
  mutate(is_valid = as.factor(is_valid))
colnames(df)


# some more checks
summary(df)

num_tests <- df %>% 
  select(doi, test_id) %>%
  unique()

check_directional_r <- df %>% filter(converted_r_es < 0)


check_num_unclear_experiment_design <- df %>% 
  filter(!is.na(converted_r_es)) %>%
  mutate(is_rm = as.factor(is_rm))
summary(check_num_unclear_experiment_design)

type_of_effect_summary <- df %>% group_by(effectsize_measure_unified, specifiers) %>% 
  summarize(n_tests = n(), 
            percentage_tests = n()/nrow(check_num_unclear_experiment_design))

type_of_test <- df %>%
  filter(!is.na(converted_r_es)) %>%
  group_by(testnames_unified) %>%
  summarize(n_tests = n(),
            percentage = n()/nrow(check_num_unclear_experiment_design))

type_of_es_and_test_summary <- df %>%
  filter(!is.na(converted_r_es)) %>%
  group_by(testnames_unified, effectsize_measure_unified, specifiers) %>%
  summarize(n_tests = n(),
            percentage = n()/nrow(check_num_unclear_experiment_design))



summary_stats <- df %>% 
  filter(!is.na(converted_r_es)) %>%
  group_by()
summary(summary_stats)
prep_weights_df <- df %>%
  filter(!is.na(converted_r_es)) %>%
  mutate(experiment_design = case_when(is_rm == "not_RM" ~ "between",
                                        is_rm == "RM" ~ "within",
                                        TRUE ~ "within"),
         experiment_design = as.factor(experiment_design)) %>%
  group_by(doi) %>%
  mutate(N_num = case_when(is.na(N_num)~mean(N_num, na.rm=TRUE),
                           TRUE ~ N_num)) %>%
  ungroup() %>%
  mutate(N_num = case_when(is.nan(N_num)~median(N_num, na.rm=TRUE),
                           TRUE ~ N_num)) %>%
  mutate(is_N_outlier = outlier_turkey(N_num, k=1.5)) %>%
  mutate(is_N_extreme_outlier = outlier_turkey(N_num, k=3)) %>%
  mutate(N_num_wo_outliers = case_when(N_num > tukey_outlier_threshold(N_num, bound="upper") ~ tukey_outlier_threshold(N_num, bound="upper"),
                                       N_num < tukey_outlier_threshold(N_num, bound="lower") ~ tukey_outlier_threshold(N_num, bound="lower"),
                                       TRUE ~ N_num)) %>%
  mutate(N_num_wo_extreme_outliers = case_when(N_num > tukey_outlier_threshold(N_num, k=3, bound="upper") ~ tukey_outlier_threshold(N_num, k=3, bound="upper"),
                                       N_num < tukey_outlier_threshold(N_num, k=3, bound="lower") ~ tukey_outlier_threshold(N_num, k=3, bound="lower"),
                                       TRUE ~ N_num)) %>%
  mutate(N_use_in_meta = N_num_wo_outliers)

summary(prep_weights_df$N_num)

tukey_outlier_threshold(prep_weights_df$N_num, bound="upper")



# Problem: Undue influence of outliers on N weighted means  

summary(as.factor(prep_weights_df$is_rm))
summary(as.factor(prep_weights_df$experiment_design))


outliers <- prep_weights_df %>% 
  filter(is_N_extreme_outlier)


ggplot(prep_weights_df, aes(N_num)) + 
  geom_boxplot()

# Topics: all, Experiment design: all
overall_analysis_summarized <- prep_weights_df %>%
  group_by(doi, topics) %>%
  summarize(mean_es_per_paper=weighted_mean(converted_r_es, weights=N_use_in_meta), 
            median_es_per_paper=weighted_median(converted_r_es, weights=N_use_in_meta), 
            sd_es_per_paper=weighted_sd(converted_r_es, weights=N_use_in_meta),
            mad_es_per_paper = weighted_mad(converted_r_es, weights=N_use_in_meta),
            num_es_per_paper = n(),
            median_N_num_per_paper = median(N_use_in_meta), 
            no_meta_max_N_per_paper = max(N_num),
            no_meta_min_N_per_paper = min(N_num),
            no_meta_median_N_per_paper = median(N_num)
            ) %>%
  ungroup() 


overall_overall_summary <- overall_analysis_summarized %>%
  ungroup() %>%
  summarize(mean_es=weighted_mean(median_es_per_paper, weights=median_N_num_per_paper), 
            quantile_33_es = weighted.quantile(median_es_per_paper, w=median_N_num_per_paper, prob=0.33),
            median_es=weighted_median(median_es_per_paper, weights=median_N_num_per_paper), 
            quantile_67_es = weighted.quantile(median_es_per_paper, w=median_N_num_per_paper, prob=0.67), 
            sd_es=weighted_sd(median_es_per_paper, weights=median_N_num_per_paper),
            mad_es = weighted_mad(median_es_per_paper, weights=median_N_num_per_paper),
            num_es = n(),
            median_N = median(median_N_num_per_paper),
            no_meta_min_N = min(no_meta_min_N_per_paper),
            no_meta_max_N = max(no_meta_max_N_per_paper),
            no_meta_median_N = median(no_meta_median_N_per_paper)
            ) %>%
  mutate(experiment_design = "all") %>%
  mutate(topic_for_analysis = "all") %>%
  select(experiment_design, topic_for_analysis, everything())


# Topics: all, Experiment design: separate
experiment_design_analysis_summarized <- prep_weights_df %>%
  group_by(doi, topics, experiment_design) %>%
  summarize(mean_es_per_paper=weighted_mean(converted_r_es, weights=N_use_in_meta), 
            median_es_per_paper=weighted_median(converted_r_es, weights=N_use_in_meta), 
            sd_es_per_paper=weighted_sd(converted_r_es, weights=N_use_in_meta),
            mad_es_per_paper = weighted_mad(converted_r_es, weights=N_use_in_meta),
            num_es_per_paper = n(),
            median_N_num_per_paper = median(N_use_in_meta),
            no_meta_max_N_per_paper = max(N_num),
            no_meta_min_N_per_paper = min(N_num),
            no_meta_median_N_per_paper = median(N_num)) %>%
  ungroup()


experiment_design_overall_summary <- experiment_design_analysis_summarized %>%
  ungroup() %>%
  group_by(experiment_design) %>%
  summarize(mean_es=weighted_mean(median_es_per_paper, weights=median_N_num_per_paper), 
            quantile_33_es = weighted.quantile(median_es_per_paper, w=median_N_num_per_paper, prob=0.33),
            median_es=weighted_median(median_es_per_paper, weights=median_N_num_per_paper), 
            quantile_67_es = weighted.quantile(median_es_per_paper, w=median_N_num_per_paper, prob=0.67),
            sd_es=weighted_sd(median_es_per_paper, weights=median_N_num_per_paper),
            mad_es = weighted_mad(median_es_per_paper, weights=median_N_num_per_paper),
            num_es = n(), 
            median_N = median(median_N_num_per_paper),
            no_meta_min_N = min(no_meta_min_N_per_paper),
            no_meta_max_N = max(no_meta_max_N_per_paper),
            no_meta_median_N = median(no_meta_median_N_per_paper)) %>%
  mutate(topic_for_analysis = "all") %>%
  select(experiment_design, topic_for_analysis, everything())

  

## Overview over experiment design
total_experiment_design <- rbind(experiment_design_overall_summary, overall_overall_summary)
rm(experiment_design_overall_summary, overall_overall_summary)

# topics prep
topics_df <- overall_analysis_summarized %>%
  separate(topics, into=c("topic_1", "topic_2", "topic_3", "topic_4", "topic_5", "topic_6", "topic_7", "topic_8"), sep=";") %>%
  pivot_longer(topic_1:topic_8, names_to="num_topic", values_to="topic") %>%
  filter(!is.na(topic)) %>%
  mutate(topic_category = case_when(topic %in% top_topics ~ topic, 
                                    topic %in% gen_ref_topics ~ "general and reference",
                                    topic %in% human_centered_comp_topics ~ "human centered computing",
                                    topic %in% security_privacy_topics ~ "security and privacy",
                                    topic %in% applied_computing_topics ~ "applied computing",
                                    TRUE ~ NA_character_)) %>%
  mutate(topic = ifelse(topic_category == "security and privacy", topic_category, topic)) %>%
  mutate(topic_for_analysis = case_when(topic == "user studies" ~ "empirical studies in hci",
                                        topic == "empirical studies in collaborative and social computing" ~ "collaborative and social computing",
                                        TRUE ~ topic))

summary(topics_df$topic_category)

summary(overall_analysis_summarized %>% mutate(doi=as.factor(doi)))
num_papers_in_full_analysis  <- overall_analysis_summarized %>% select(doi) %>% unique() 

double_report <- df %>% filter(doi=="10.1145/3313831.3376346")


topics_list <- topics_df %>% 
  group_by(topic_category, topic_for_analysis) %>%
  summarize(n=n()) %>%
  arrange(-n) %>%
  head(12) 

topics_list

reduced_topics_df <- topics_df %>% 
  filter(topic_for_analysis %in% topics_list$topic_for_analysis)

num_papers_topics <- reduced_topics_df %>% select(doi) %>% unique()
nrow(num_papers_topics)

#excluded papers
nrow(num_papers_in_full_analysis) - nrow(num_papers_topics)

# Topics: separate, experiment design: all
topics_summary <- reduced_topics_df %>% 
  group_by(topic_for_analysis) %>%
  summarize(mean_es=weighted_mean(median_es_per_paper, weights=median_N_num_per_paper), 
            quantile_33_es = weighted.quantile(median_es_per_paper, w=median_N_num_per_paper, prob=0.33),
            median_es=weighted_median(median_es_per_paper, weights=median_N_num_per_paper), 
            quantile_67_es = weighted.quantile(median_es_per_paper, w=median_N_num_per_paper, prob=0.67),
            sd_es=weighted_sd(median_es_per_paper, weights=median_N_num_per_paper),
            mad_es = weighted_mad(median_es_per_paper, weights=median_N_num_per_paper),
            num_es = n(),
            median_N = median(median_N_num_per_paper),
            no_meta_min_N = min(no_meta_min_N_per_paper),
            no_meta_max_N = max(no_meta_max_N_per_paper),
            no_meta_median_N = median(no_meta_median_N_per_paper)) %>%
  mutate(experiment_design = "all") %>%
  select(experiment_design, everything())


# Topics: separate,  experiment design: separate
topics_experiment_design_df <- experiment_design_analysis_summarized %>%
  separate(topics, into=c("topic_1", "topic_2", "topic_3", "topic_4", "topic_5", "topic_6", "topic_7", "topic_8"), sep=";") %>%
  pivot_longer(topic_1:topic_8, names_to="num_topic", values_to="topic") %>%
  filter(!is.na(topic)) %>%
  mutate(topic_category = case_when(topic %in% top_topics ~ topic, 
                                    topic %in% gen_ref_topics ~ "general and reference",
                                    topic %in% human_centered_comp_topics ~ "human centered computing",
                                    topic %in% security_privacy_topics ~ "security and privacy",
                                    topic %in% applied_computing_topics ~ "applied computing",
                                    TRUE ~ NA_character_)) %>%
  mutate(topic = ifelse(topic_category == "security and privacy", topic_category, topic)) %>%
  mutate(topic_for_analysis = case_when(topic == "user studies" ~ "empirical studies in hci",
                                        topic == "empirical studies in collaborative and social computing" ~ "collaborative and social computing",
                                        TRUE ~ topic)) %>%
  filter(topic_for_analysis %in% topics_list$topic_for_analysis) 


for_vis <- experiment_design_analysis_summarized %>% 
  mutate(num_topic= "not relevant",
         topic = "all",
         topic_category = "all", 
         topic_for_analysis = "all") %>%
  select(-topics) %>% rbind(topics_experiment_design_df)

write.csv(for_vis, file.path(clean_data_path, "per_paper_summarized_for_visualizations.csv"), row.names=FALSE)
  
topics_experiment_design_summary <- topics_experiment_design_df %>%
  group_by(experiment_design, topic_for_analysis) %>%
  summarize(mean_es=weighted_mean(median_es_per_paper, weights=median_N_num_per_paper), 
            quantile_33_es = weighted.quantile(median_es_per_paper, w=median_N_num_per_paper, prob=0.33),
            median_es=weighted_median(median_es_per_paper, weights=median_N_num_per_paper), 
            quantile_67_es = weighted.quantile(median_es_per_paper, w=median_N_num_per_paper, prob=0.67),
            sd_es=weighted_sd(median_es_per_paper, weights=median_N_num_per_paper),
            mad_es = weighted_mad(median_es_per_paper, weights=median_N_num_per_paper),
            num_es = n(),
            median_N = median(median_N_num_per_paper),
            no_meta_min_N = min(no_meta_min_N_per_paper),
            no_meta_max_N = max(no_meta_max_N_per_paper),
            no_meta_median_N = median(no_meta_median_N_per_paper)) %>%
  select(experiment_design, everything())

#View(topics_experiment_design_summary)


overall_summary <- rbind(total_experiment_design, topics_summary, topics_experiment_design_summary)
rm(total_experiment_design, topics_summary, topics_experiment_design_summary)

write.csv(overall_summary, file.path(clean_data_path, "per_topic_experiment_design_summarized_for_vis.csv"), row.names = FALSE)

