#---------------------------------------------------------------------------
#
# Use meta-analyzed data to calculate effect size thresholds based on method 
# from Obukhova (2021), https://dl.acm.org/doi/abs/10.1145/3411763.3451520
#
#---------------------------------------------------------------------------
library(tidyverse)
library(modi) # for weighted quantiles
library(xtable) # to write latex tables for the paper
source("00_ES_conversion_functions.R")

general_data_path <- file.path("..", "Data")
clean_data_path <- file.path(general_data_path, "R_clean_data")
supplemental_path <- file.path(general_data_path, "for_supplemental")

summary_df <- read.csv(file.path(clean_data_path, "per_topic_experiment_design_summarized_for_vis.csv"))
colnames(summary_df)

# This df contains the Ns used for weighting in the meta analysis
ns_to_merge <- summary_df %>% 
  filter(experiment_design != "all") %>%
  select(experiment_design, topic_for_analysis, num_es, median_N) %>%
  pivot_longer(num_es:median_N, names_to="names", values_to="values") %>%
  unite(experiment_design, names, col="design_value", sep="__") %>%
  pivot_wider(names_from=design_value, values_from=values)

# This df contains the raw Ns (too large for using as weights)
no_meta_ns <- summary_df %>% 
  filter(experiment_design != "all") %>%
  select(experiment_design, topic_for_analysis, num_es, median_N, no_meta_min_N, no_meta_median_N, no_meta_max_N) %>%
  mutate(no_meta_min_N = round(no_meta_min_N, 0),
         no_meta_max_N = round(no_meta_max_N, 0)) %>%
  pivot_longer(num_es:no_meta_max_N, names_to="names", values_to="values") %>%
  unite(experiment_design, names, col="design_value", sep="__") %>%
  pivot_wider(names_from=design_value, values_from=values)

guidelines_to_be <- summary_df %>%
  select(experiment_design, topic_for_analysis, quantile_33_es, quantile_67_es) 

df <- read.csv(file.path(clean_data_path, "per_paper_summarized_for_visualizations.csv")) %>% 
  left_join(guidelines_to_be) %>%
  mutate(guided_size = case_when(median_es_per_paper < quantile_33_es ~ "small",
                                 median_es_per_paper > quantile_67_es ~ "large",
                                 median_es_per_paper <= quantile_67_es & median_es_per_paper >= quantile_33_es ~ "medium",
                                 TRUE ~ "whatever")) %>%
  mutate(guided_size = as.factor(guided_size))


guidelines <- df %>% 
  group_by(experiment_design, topic_for_analysis, guided_size) %>% 
  summarize(guideline_r = weighted.quantile(median_es_per_paper, median_N_num_per_paper, prob=0.5),
            guideline_non_weighted = median(median_es_per_paper),
            n_values = n()) %>% 
  mutate(guideline_cramersv = meta_convert_r_to_es_vectors(guideline_r, "cramers_v" ),
         guideline_spearmansrho =  meta_convert_r_to_es_vectors(guideline_r, "spearmans_rho"),
         guideline_kendallstau = meta_convert_r_to_es_vectors(guideline_r, "kendalls_tau" ),
         guideline_cohensd = meta_convert_r_to_es_vectors(guideline_r, "cohens_d" ),
         guideline_or = meta_convert_r_to_es_vectors(guideline_r, "odds_ratio" ),
         guideline_Rsquared = meta_convert_r_to_es_vectors(guideline_r, "r_squared" ),
         guideline_fsquared = meta_convert_r_to_es_vectors(guideline_r, "f_squared" ),
         guideline_cohensf = meta_convert_r_to_es_vectors(guideline_r, "cohens_f" ),
         guideline_cles = meta_convert_r_to_es_vectors(guideline_r, "cles")
         )

write.csv(guidelines, file.path(clean_data_path, "guidelines.csv"), row.names=FALSE)

dplyr::last_dplyr_warnings()

# To check for each of the warnings, uncomment only one of the lines at a time
check_undue_influence <- df %>% 
  #filter(experiment_design == "within" & topic == "computing methodologies" & guided_size == "small") #downwards (large N, small es)
  #filter(experiment_design == "between", topic == "interaction design", guided_size == "large") # downwards (large N, small es)
  #filter(experiment_design == "within", topic == "interaction design", guided_size == "medium") # downwards (large N, small es)
  filter(experiment_design == "within", topic == "interaction design", guided_size == "small") # only two papers, but close estimates


guidelines_table <- guidelines %>%
  select(experiment_design, topic_for_analysis, guided_size, n_values, guideline_non_weighted, everything()) %>% 
  select(-guideline_non_weighted) %>%
  pivot_longer(guideline_r:guideline_cles, names_to="effectsize_measure", values_to="values") %>% 
  mutate(values = round(values, 3)) %>%
  separate(effectsize_measure, into=c("temp", "effectsize_measure"), sep="_") %>%
  select(-temp) %>%
  select(-n_values) %>%
  unite(experiment_design, guided_size, col="design_size", sep="_") %>%
  pivot_wider(names_from=design_size, values_from=values) %>%
  #mutate(effectsize_measure = factor(effectsize_measure, ordered=TRUE, c("r", "cohensd", "or",
  #                                                                       "Rsquared", "spearmansrho", "kendallstau",
  #                                                                       "cohensf", "fsquared", "cramersv", "cles"))) %>%
  full_join(ns_to_merge) %>%
  arrange(effectsize_measure, topic_for_analysis) %>%
  ungroup()

guidelines_all_es <- guidelines_table %>%
  filter(topic_for_analysis == "all") %>%
  select(-topic_for_analysis, -between__num_es, -between__median_N, -within__num_es, -within__median_N) %>%
  select(effectsize_measure, between_small, between_medium, between_large, within_small, within_medium, within_large)

colnames(guidelines_all_es)
guidelines_r <- guidelines_table %>% 
  filter(effectsize_measure =="r") %>%
  select(-effectsize_measure, -between__num_es, -between__median_N, -within__num_es, -within__median_N)

# prepare basic tables in LaTeX, which can be slightly adjusted and used in the publication

caption_estype <- "Guidelines for separate research areas, using "
label_estype1 <- "es guidelines "
label_estype2 <- "-es different topics"
caption_all_es = "Guidelines including all research areas and for all effect size measures, median number of included papers 359 for between groups designs and 346 for within groups designs, median sample size 50 for between groups designs and 28.5 for within groups designs"
label_all_es = "es guidelines all-es all-topics"
caption_ns <- "Median sample sizes and number of papers in meta-study for each research area"
label_ns <- "reliability judgment table"

guidelines_r <- guidelines_table %>% filter(effectsize_measure =="r")
summary(guidelines_table)
write.csv(guidelines_table, file.path(supplemental_path, "guidelines_table.csv"), row.names = FALSE)

as.factor(guidelines_table$effectsize_measure)

guidelines_table_paper <- guidelines_table %>%
  filter(effectsize_measure %in% c("r", "cohensd", "or", "Rsquared", "cles"))
  


get_researcharea_guideline_table <- function(effectsize_measure_name, df){
  guidelines <- df %>% 
    filter(effectsize_measure ==effectsize_measure_name) %>%
    select(-effectsize_measure, -between__num_es, -between__median_N, -within__num_es, -within__median_N) %>%
    select(topic_for_analysis, between_small, between_medium, between_large, within_small, within_medium, within_large)
  return(guidelines)
  
}

write_guideline_table <- function(table, caption, label){
  final_label <- paste("tab:", label, sep="")
  file_name <- file.path(supplemental_path, paste(label, ".tex", sep=""))
  print(file_name)
  tex_table <- print(xtable(table, type="latex", caption=caption, label=final_label), type="latex", include.rownames = FALSE)
  write(tex_table, file=file_name )
}

write_guideline_table(no_meta_ns %>% select(-within__median_N, -between__median_N),caption_ns, label_ns)

write_guideline_table(guidelines_all_es, caption_all_es, label_all_es)
write_guideline_table(get_researcharea_guideline_table("r", guidelines_table), 
                       caption=paste(caption_estype, "Pearson's r", sep=""), 
                       label = paste(label_estype1, "r", label_estype2, sep=""))
write_guideline_table(get_researcharea_guideline_table("cohensd", guidelines_table), 
                      caption=paste(caption_estype, "Cohen's d", sep=""), 
                      label = paste(label_estype1, "cohensd", label_estype2, sep=""))
write_guideline_table(get_researcharea_guideline_table("or", guidelines_table), 
                      caption=paste(caption_estype, "\\ac{OR}", sep=""), 
                      label = paste(label_estype1, "or", label_estype2, sep=""))
write_guideline_table(get_researcharea_guideline_table("Rsquared", guidelines_table), 
                      caption=paste(caption_estype, "$\\eta^2$, $R^2$, $\\omega^2$, $\\eta^2$ or related effect size measures", sep=""), 
                      label = paste(label_estype1, "etasquared", label_estype2, sep=""))
write_guideline_table(get_researcharea_guideline_table("cles", guidelines_table), 
                      caption=paste(caption_estype, "\\ac{CLES}", sep=""), 
                      label = paste(label_estype1, "cles", label_estype2, sep=""))
write_guideline_table(get_researcharea_guideline_table("spearmansrho", guidelines_table), 
                      caption=paste(caption_estype, "Spearman's $\rho$", sep=""), 
                      label = paste(label_estype1, "spearmansrho", label_estype2, sep=""))
write_guideline_table(get_researcharea_guideline_table("kendallstau", guidelines_table), 
                      caption=paste(caption_estype, "Kendall's $\tau$", sep=""), 
                      label = paste(label_estype1, "kendallstau", label_estype2, sep=""))
write_guideline_table(get_researcharea_guideline_table("cohensf", guidelines_table), 
                      caption=paste(caption_estype, "Cohen's f", sep=""), 
                      label = paste(label_estype1, "cohensf", label_estype2, sep=""))
write_guideline_table(get_researcharea_guideline_table("fsquared", guidelines_table), 
                      caption=paste(caption_estype, "$f^2$", sep=""), 
                      label = paste(label_estype1, "fsquared", label_estype2, sep=""))
write_guideline_table(get_researcharea_guideline_table("cramersv", guidelines_table), 
                      caption=paste(caption_estype, "Cramer's V", sep=""), 
                      label = paste(label_estype1, "cramersv", label_estype2, sep=""))





