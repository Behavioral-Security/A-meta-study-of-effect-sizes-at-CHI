-------------------------------------------------------------------------------
#
# Converts all relevant effect sizes to a single type of effect size
# Also contains some further plausibility checks on the effect sizes
#
#
-------------------------------------------------------------------------------


library(tidyverse)
source("00_ES_conversion_functions.R")

general_data_path <- file.path("..", "Data")
todo_manual_path <- file.path(general_data_path, "R_todo_manual_check")
done_manual_check_path <- file.path(general_data_path, "R_done_manual_check")
side_output_path <- file.path(general_data_path, "R_side_output_data")
clean_data_path <- file.path(general_data_path, "R_clean_data")

df <- read.csv(file.path(clean_data_path, "unified_plausibilitychecked_factorduplicatesremoved_2019-23.csv")) %>%
  mutate(effectsize_measure_unified = as.factor(effectsize_measure_unified)) %>%
  mutate(across(c(N_found:CI_type_found), ~as.logical(.x))) %>%
  mutate(effectsize_value = case_when(effectsize_value == "" ~ NA_real_,
                                      TRUE ~ as.numeric(effectsize_value))) %>%
  mutate(is_valid = is_valid_es_vectors(es_value=effectsize_value, es_type = effectsize_measure_unified)) %>%
  mutate(converted_r_es = case_when(is_valid == TRUE ~ meta_convert_es_to_r_vectors(es_value=effectsize_value, es_type=effectsize_measure_unified),
                                    TRUE ~ NA_real_))

summary(df)

write.csv(df, file.path(clean_data_path, "unified_factor_duplicates_removed_es_converted_2019-23.csv"), row.names=FALSE)


## Some effect sizes plausibility checks
# check the non-valid ES
non_valid_es <- df %>% filter(!is_valid)
test <- is_valid_es(es_value=df$effectsize_value, es_type=df$effectsize_measure_unified)

summary(df$effectsize_measure_unified)

# check plausibility_check
only_valid <- df %>% 
  filter(is_valid)
nrow(only_valid)

only_present <- only_valid %>%
  filter(N_found == TRUE, effectsize_value_found == TRUE)
nrow(only_present)

not_present_es_n <- only_valid %>%
  filter(!N_found | !effectsize_value_found )
nrow(not_present_es_n)

not_present_es <- not_present_es_n %>%
  filter(!effectsize_value_found)

not_present_n <- not_present_es_n %>%
  filter(!N_found)

write.csv(not_present_es, file.path(todo_manual_path,"plausibility_check_es_not_found.csv"), row.names=FALSE)
write.csv(not_present_n, file.path(todo_manual_path,"plausibility_check_n_not_found.csv"), row.names=FALSE)
# TODO At this point manual checking is necessary: 
# we check whether the es (or N) value is only missing because the LLM did not 
# find it or because it is actually not reported in the paper 

summary(only_valid)

not_present_es <- read.csv(file.path(done_manual_check_path,"plausibility_check_es_not_found_done.csv")) %>%
  select(doi, topics, test_id, test_name, factor, effectsize_id, manual_is_found_es) %>% unique()

not_present_n <- read.csv(file.path(done_manual_check_path,"plausibility_check_n_not_found_done.csv")) %>%
  select(doi, topics, test_id, test_name, factor, effectsize_id, N_found_manual)


check_N_numeric <- only_valid %>% 
  mutate(N_num_test = as.numeric(N)) %>%
  filter(is.na(N_num_test)) %>%
  select(N_num_test, N, everything()) %>%
  mutate(N_num_test = case_when(N=="50 (initially), 19 (after filtering)"~ "50",
                                N=="289 million" ~ "289000000"))


manual_plausibility_check_added <- only_valid %>% 
  full_join(not_present_es) %>% 
  full_join(not_present_n) %>% 
  mutate(N = case_when(N=="50 (initially), 19 (after filtering)"~ "50",
                       N=="289 million" ~ "289000000", # check this as extreme by large value outlier
                       TRUE ~ N)) %>%
  mutate(effectsize_value_found = case_when(manual_is_found_es == "TRUE" ~  TRUE,
                                            TRUE ~ effectsize_value_found),
         N_found = case_when(N_found_manual == "TRUE" ~ TRUE,
                             TRUE ~ N_found)) %>%
  mutate(converted_r_es = case_when(effectsize_value_found != TRUE ~ NA,
                                    TRUE ~ converted_r_es)) %>%
  mutate(N_num = case_when(N_found != TRUE ~ NA_real_,
                           TRUE ~ as.numeric(N))) %>%
  mutate(N_num = case_when(N_found != TRUE ~ NA_real_,
                           TRUE ~ N_num))


summary(only_valid)
summary(manual_plausibility_check_added)

# data with which we will be working for meta analysis
write.csv(manual_plausibility_check_added, file.path(clean_data_path, "unified_manualPlausibilitychecked_factorduplicatesremoved_2019-23.csv"), row.names = TRUE)


# data to work with in developing automated plausibility checking
dev_plausibility_check <- manual_plausibility_check_added %>% filter(!effectsize_value_found)
write.csv(dev_santity_check, file.path(side_output_path, "manual_check_es_not_found_done.csv"), row.names=FALSE)
