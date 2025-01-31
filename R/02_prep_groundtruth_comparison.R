#------------------------------------------------------------------------------
# 
# This script prepares data so that human and LLM extracted data are in a 
# similar format to make comparing them easier.
#
#------------------------------------------------------------------------------


library(tidyverse)
library(readODS)
source("00_utility_functions.R")

## paths
ground_truth_overview_path <- file.path("..", "Data", "ground_truth", "sample_for_ground_truth_manually_annotated.ods")
human_ground_truth_path <- file.path("..", "Data", "ground_truth", "human_ground_truth.csv")
output_path <- file.path("..", "Data", "R_todo_manual_check", "from_llm_for_groundtruth_todo.csv")
manual_check_done_path <- file.path("..", "Data" ,"R_todo_manual_check", "compare_from_human_done.csv")



## llm data
df_llm <- read_all_years_csv()

## human data
ground_truth_overview <-  read_ods(ground_truth_overview_path)
checked <- ground_truth_overview %>% 
  filter(checked == "TRUE") %>%
  separate(paper, into=c("doi_part", "temp"), sep="\\.") %>%
  mutate(doi_part = trimws(doi_part))

human_ground_truth <- read.csv(human_ground_truth_path) %>%
  mutate(doi = ifelse(doi == "10.1145/3491102. 3501999", "10.1145/3491102.3501999", doi)) %>%
  separate(doi, remove=FALSE, into=c("temp", "temp2", "doi_part"), sep="\\.") %>%
  select(-temp, -temp2)

dois_to_compare <- pull(human_ground_truth, doi) %>% unique()
dois_to_compare
joined <- full_join(checked, human_ground_truth, by="doi_part")

pull(joined, title) %>% unique()


## llm to compare
llm_to_compare <- df_llm %>%
  filter(doi %in% dois_to_compare) %>%
  select(-topics) %>%
  arrange(doi, test_id)


llm_present_dois <- llm_to_compare %>% 
  pull(doi) %>% 
  unique() 


llm_present_dois

write.csv(llm_to_compare, "todo_manual_check/from_llm_for_groundtruth_todo.csv", row.names=FALSE)

pre_work <- read.csv("todo_manual_check/compare_from_human_done.csv") %>%
  mutate(done="done")

done_dois <- pre_work %>% pull(doi) %>% unique()
done_dois

## human to compare
human_to_compare <- human_ground_truth %>% 
  filter(doi == "10.1145/3411764.3445523") %>%
  #filter(doi %in% llm_present_dois) %>%
  select(-doi_part, -topics) %>%
  #filter(!(doi %in% done_dois)) %>%
  mutate(test_name_correct = "",
         ES_correct = "",
         ES_name_correct = "",
         p_vals_correct = "",
         Ns_correct ="",
         Cis.correct = "",
         fully_correct = "",
         added_info = "",
         added_undectably_wrong_info = "",
         missing = "",
         double.reported = "",
         format_error = "",
         problem_reason ="",
         done ="") %>%
 # rbind(pre_work) %>%
  arrange(doi, test_id) %>%
  mutate(missing = 1)
colnames(pre_work)
colnames(human_to_compare)

colnames(llm_to_compare)

write.csv(human_to_compare, "todo_manual_check/compare_from_human.csv", row.names=FALSE, na="")
