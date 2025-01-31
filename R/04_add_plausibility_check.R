#------------------------------------------------------------------------------
#
# This script merges the plausibility checked and unified (Script 03_unify_stuff.R) data sets.
# The actual plausibility check happens in Python, see repo read.me
#
#------------------------------------------------------------------------------

library(tidyverse)
source("00_utility_functions.R")


general_data_path <- file.path("..", "Data")
extracted_data_path <- file.path(general_data_path, "extracted_data", "plausibility_checked")
clean_data_path <- file.path(general_data_path, "R_clean_data")


plausibility_checked <- read_all_years_csv(base_path=extracted_data_path) %>%
  mutate(across(N_found:CI_type_found, ~as.factor(.x))) %>%
  mutate(year = as.numeric(year)) %>%
  mutate(test_name = trimws(test_name)) %>%
  mutate(test_name = tolower(test_name)) %>% 
  unique() %>%
  mutate(effectsize_value = case_when(is.na(effectsize_value) ~ "", 
                                      effectsize_value == "N/A" ~ "", 
                                      TRUE ~ effectsize_value)) %>%
  mutate(test_p_value = case_when(test_p_value == "" ~ "",
                                  test_p_value == "N/A" ~ "",
                                  TRUE ~ test_p_value)) %>%
  mutate(CI_type = case_when(CI_type == "" ~ "",
                             CI_type == "N/A" ~ "",
                             CI_type == "None" ~ "",
                             TRUE ~ CI_type)) %>%
  mutate(CI_upper = case_when(CI_upper == "" ~ "",
                              CI_upper == "N/A" ~ "",
                              TRUE ~ CI_upper)) %>%
  mutate(CI_lower = case_when(CI_lower == "" ~ "",
                              CI_lower == "N/A" ~ "",
                              TRUE ~ CI_lower)) %>%
  mutate(effectsize_measure = case_when(effectsize_measure == "" ~ "",
                                        effectsize_measure == "N/A" ~ "",
                                        TRUE ~ effectsize_measure)) %>% unique()

summary(plausibility_checked)

unified <- read.csv(file.path(clean_data_path, "unified_tests_and_ES_2019-23.csv")) %>% unique() %>%
  mutate(effectsize_value = case_when(is.na(effectsize_value) ~ "", 
                                      effectsize_value == "N/A" ~ "", 
                                      TRUE ~ effectsize_value)) %>%
  mutate(test_p_value = case_when(test_p_value == "" ~ "",
                                  test_p_value == "N/A" ~ "",
                                  TRUE ~ test_p_value)) %>%
  mutate(CI_type = case_when(CI_type == "" ~ "",
                             CI_type == "N/A" ~ "",
                             CI_type == "None" ~ "",
                             TRUE ~ CI_type)) %>%
  mutate(CI_upper = case_when(CI_upper == "" ~ "",
                             CI_upper == "N/A" ~ "",
                             TRUE ~ CI_upper)) %>%
  mutate(CI_lower = case_when(CI_lower == "" ~ "",
                             CI_lower == "N/A" ~ "",
                             TRUE ~ CI_lower)) %>%
  mutate(effectsize_measure = case_when(effectsize_measure == "" ~ "",
                                        effectsize_measure == "N/A" ~ "",
                                        TRUE ~ effectsize_measure)) %>% unique()
test <- anti_join(unified, plausibility_checked)
test2 <- anti_join(plausibility_checked, unified)


unified_checked <- full_join(unified, plausibility_checked) %>%
  mutate(doi = case_when(doi == "10.1145/3313831.3376346" & topics == "human and societal aspects of security and privacy;security and privacy" ~ "10.1145/3313831.3376651",
                         doi == "10.1145/3313831.3376442" & topics == "text input;human-centered computing" ~ "10.1145/3313831.3376441",
                         doi == "10.1145/3313831.3376457" & topics == "software security engineering;security and privacy;hci design and evaluation methods;human-centered computing" ~ "10.1145/3313831.3376754",
                         doi == "10.1145/3411764.3445708" & topics == "computing methodologies" ~ "10.1145/3411764.3445719",
                         TRUE ~ doi)) 

write.csv(unified_checked, file.path(clean_data_path,"unified_plausibility_checked_2019-2023.csv"), row.names=FALSE)  
