# -----------------------
#
# Draw a sample of 10 papers per year from CHI to analyze manually for ground truth
#
# -----------------------

library(tidyverse)
path_to_csv_list_of_CHI_papers <- file.path("..", "Data", "list_of_all_CHI_papers")
path_to_groundtruth <- file.path("..", "Data", "ground_truth")

read_paper_list <- function(year, path=path_to_csv_list_of_CHI_papers, file="_full_selection.csv"){
  full_path = file.path(path, paste( year, file,  sep=""))
  df <- read.csv2(full_path) %>%
    separate(Paper, sep="/", into=c("year", "paper"))
}


df_total <- read_paper_list(2019) %>%
  rbind(read_paper_list(2020)) %>%
  rbind(read_paper_list(2021)) %>%
  rbind(read_paper_list(2022)) %>%
  rbind(read_paper_list(2023)) %>%
  mutate(year = as.factor(year), 
         across(one_true:bayes, ~as.logical(.)))
summary(df_total)
3280/nrow(df_total)

df_quant <- df_total %>%
  filter(one_true == TRUE)

num_quant_per_year <- df_quant %>%
  group_by(year) %>%
  summarize(n = n())

bayes <- df_total %>% filter(bayes)
nrow(bayes)/nrow(df_quant)


summary(df_quant)

sample_by_year <- df_quant %>%
  group_by(year) %>%
  sample_n(5)
summary(sample_by_year)

write.csv2(sample_by_year, 
          file.path(path_to_groundtruth, "sample_for_ground_truth.csv"), 
          row.names=FALSE)  

