#-----------------------------------------------------------------------------
#
# This script evaluates the ground-truth comparison.
# The ground truth is manually evaluated. 
# Format description in the done_manual_check data.
# The script focuses especially on correctness and presence of effect size and 
# participant number and test names.
#
#-----------------------------------------------------------------------------
library(tidyverse)

general_data_path <- file.path("..", "Data")
done_manual_check_path <- file.path(general_data_path, "R_done_manual_check")


human_groundtruth_done <- read.csv(file.path(done_manual_check_path, "compare_from_human_done2.csv"))


relevant_sample <- human_groundtruth_done %>% 
  mutate(es_num = as.numeric(effectsize_value)) %>%
  mutate(has_es = case_when(!is.na(es_num) ~ TRUE,
                            TRUE ~ FALSE)) %>%
  filter(has_es == TRUE) %>% # comment out this line if you want to check those tests which did not report ES
  mutate(measure_factor = as.factor(effectsize_measure)) %>%
  mutate(measure_unified = case_when(grepl("regression coefficient", effectsize_measure) ~ "regression_coefficient",
                                     grepl("beta", effectsize_measure) ~ "regression_coefficient",
                                     grepl("indirect effect coefficient", effectsize_measure) ~ "regression_coefficient",
                                     effectsize_measure == "index of moderated mediation (MM)" ~ "regression_coefficient",
                                     effectsize_measure %in% c("r ^2", "R^2", "Total R^2", "r^2","r ^2 ", "Incremental R^2") ~ "R_squared",
                                     effectsize_measure %in% c("η^2_G", "η^2p", "η^2") ~ "eta_squared",
                                     effectsize_measure == "d" ~ "Cohen's d",
                                     effectsize_measure %in% c("correlation coefficient", "cor") ~ "correlation_coefficient_unspecified",
                                     TRUE ~ effectsize_measure
                                     ),
         measure_unified = as.factor(measure_unified)) %>%
  mutate(is_relevant = case_when(measure_unified %in% c("correlation_coefficient_unspecified", "regression_coefficient") ~ FALSE,
                                 TRUE ~ TRUE)) %>% # comment this if you want to see the numbers for non-relevant ES
  filter(is_relevant == TRUE)

summary(relevant_sample$measure_unified)  
summary(relevant_sample)
273+130 # non_relevant ES + relevant ES



check_ns <-  relevant_sample %>% select(doi:N, test_name_correct:format_error) %>%
  unique() %>%
  filter(!is.na(test_id)) %>%
  mutate(human_has_n = ifelse(!is.na(N), TRUE, FALSE)) %>%
  mutate(Ns_correct = case_when(missing == 1 ~ "test not extracted",
                                human_has_n == FALSE ~ "not reported with n", 
                                fully_correct == 1 ~ "1",
                                TRUE~ Ns_correct)) %>%
  mutate(Ns_correct = as.factor(Ns_correct))
summary(check_ns)

summary(check_ns$Ns_correct)

# Ns
# 49 correct
# 12 wrong
# 1 missing from human data/not reported in paper
# 26 not included in LLM output


# N from non-relevant ES included
# 12 wrong
# 98 correct
# 3 not reported in paper
# 52 not included in LLM output

# N also from tests without ES
# 191 correct
# 38 wrong - over-generalized (authors were analyzing sub-sample)
# 6 human annotator was unsure
# 362 records were not included in LLM output
# 5 not reported with n


summary(human_groundtruth_done)
check_tests <- relevant_sample %>% select(doi:N, test_name_correct:format_error) %>%
  unique() %>%
  group_by(doi, test_id) %>%
  mutate(human_has_n = ifelse(!is.na(N), TRUE, FALSE)) %>%
  mutate(Ns_correct = case_when(fully_correct == 1 ~ 1,
                                missing == 1 ~ NA_real_,
                                Ns_correct == "?" ~ -1000,
                                TRUE~ as.numeric(Ns_correct))) %>%
  summarize(n=n(),
            num_testnamecorrect = sum(test_name_correct, na.rm=TRUE),
            num_missing = sum(missing, na.rm=TRUE),
            num_ncorrect = sum(Ns_correct, na.rm=TRUE)
            ) %>%
  ungroup() %>%
  filter(!is.na(test_id)) %>%
  mutate(is_testnamecorrect = case_when(num_testnamecorrect == n ~ "completely",
                                        num_missing == n ~ "test missing",
                                        num_testnamecorrect + num_missing == n ~ "completely",
                                        num_testnamecorrect == 0  ~ "not at all",
                                        num_testnamecorrect < n ~ "partially",
                                        TRUE ~ ""),
         is_testnamecorrect = as.factor(is_testnamecorrect),
         is_ncorrect = case_when(num_ncorrect == n ~ "completely",
                                 num_missing == n ~ "test missing",
                                 num_ncorrect + num_missing == n ~ "completely",
                                 num_ncorrect == 0 ~ "not at all",
                                 num_ncorrect == -1000 ~ "human annotator unsure",
                                 TRUE ~ ""),
         is_ncorrect = as.factor(is_ncorrect))

summary(check_tests)
summary(check_tests$is_testnamecorrect)

# test names:
# 68 correct
# 14 wrong
# 9 partially correct
# 51 test missing / not reported


# Try to find patterns among the missing data - makes more sense in larger sample (not just those with relevant ES)
missingness <- relevant_sample %>% 
  filter(missing == "1") %>%
  mutate(has_es = case_when(effectsize_value != "" ~ TRUE,
                            TRUE ~ FALSE)) %>%
  mutate(test_p_value = trimws(test_p_value), 
         test_p_value = case_when(test_p_value == ">.05" ~ ">0.05",
                                  test_p_value == "> .05" ~ ">0.05",
                                  test_p_value == "p<0.05" ~ "<0.05",
                                  test_p_value == "<.05" ~ "<0.05",
                                  test_p_value == "< .05" ~ "<0.05",
                                  test_p_value == "<.001" ~ "<0.001",
                                  test_p_value == "<.0001" ~ "<0.0001",
                                  test_p_value == "<.005" ~ "<0.005",
                                  TRUE ~ test_p_value),
         test_p_value = as.factor(test_p_value))
summary(missingness)
summary(missingness$test_p_value)

missingness$test_p_value
levels(missingness$test_p_value)

missing_es <- missingness %>% filter(has_es) %>%
  mutate(problem_reason = case_when(doi == "10.1145/3491102.3501848" & problem_reason == "" ~ "reported only in table",
                                    doi == "10.1145/3491102.3502027" & problem_reason == "" ~ "reported in method section",
                                    doi == "10.1145/3411764.3445109" & problem_reason == "" ~ "reported only in table + non-significant?",
                                    doi == "10.1145/3491102.3517495" & problem_reason == "" ~ "no 'statistics sign-posts close",
                                    doi == "10.1145/3544548.3581087" & problem_reason == "" ~ "unclear",
                                    TRUE ~ problem_reason)) %>%
  mutate(doi = as.factor(doi)) %>%
  mutate(problem_reason = as.factor(problem_reason))

summary(missing_es)
summary(missing_es$problem_reason)

check_es <- relevant_sample %>% 
  mutate(has_es = case_when(effectsize_value != "" ~ TRUE,
                            TRUE ~ FALSE)) %>%
  mutate(ES_correct = case_when(fully_correct == 1 ~ "1",
                                !has_es ~ "no es in human",
                                missing == 1 ~ NA_character_,
                                TRUE~ as.character(ES_correct)),
         ES_correct = as.factor(ES_correct))

summary(check_es)

only_where_es_present <- check_es %>% 
  filter(has_es)

summary(only_where_es_present)
summary(check_es$ES_correct)
# Effectsizes: 
# 2 instances - where sign is missing
# 86 correct
# 42 missing

# from non-relevant ES included
# 2 instances - where sign is missing
# 214 correct
# 187 missing

# ES also from tests without ES
# 2 instances - where sign is missing
# 279 correct
# 531 no es in human data
# 188 missing
# majority of missing es: reported only in table or in methods section -> no statistics sign-posts close (d=kkk)




