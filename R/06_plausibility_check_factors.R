-------------------------------------------------------------------------------
#
# remove artefacts of double reported factor and main test ES
#  
# Go through df row by row  
#   if current test != test [row-1] # erste Reihe pro test
#     delete all row ids collected for potential deletion
#       if factor == "" # we're looking at a row of omnibus tests (directly test associated ES)
#         collect row id for potential deletion in list
#       if factor != "" # we're looking at a row of factors
#         go through list of all collected row ids
#           check if the data in that row is the same as in the current factor
#           if yes:
#             mark that row in the df as to be deleted
#             delete that row from the list of potential deletion (since it's not potential anymore)
#  
-------------------------------------------------------------------------------

library(tidyverse)
source("00_utility_functions.R")

general_data_path <- file.path("..", "Data")
side_output_path <- file.path(general_data_path, "R_side_output_data")
clean_data_path <- file.path(general_data_path, "R_clean_data")

df_full <- read.csv(file.path(clean_data_path, "unified_plausibility_checked_2019-2023.csv"))


# prepare data frame for duplicate removal
# make factors comparable
# add column to mark for deletion during de-duplication
# replace NAs with "" so null values are represented equally (error prevention)

test_df <- df_full %>% 
  mutate(factor = trimws(factor)) %>%
  mutate(to_delete = FALSE) %>%
  mutate(across(c(factor, effectsize_measure:CI_type), ~ifelse(is.na(.), "", .))) 

# handle different cases of "factor" rows and "omnibus" rows
handle_row_types <- function(test_df, poss_delete_list, row){
  if(test_df[row,]$factor == ""){ 
    # ES is associated with omnibus test (not factor) - candidate for deletion
    poss_delete_list <- append(poss_delete_list, row)
    return_list <- list("test_df"=test_df, "poss_delete_list"=poss_delete_list)
    return(return_list)
  } else {
    # ES is associated with factor - look for duplicates
    return(mark_duplicates_of_factor(test_df, poss_delete_list, row))

    
  }
}

# mark omnibus rows that are the same as current row (row), as "to be deleted"
mark_duplicates_of_factor <- function(test_df, poss_delete_list, row){
  for (poss_delete in poss_delete_list){
    if(is_equal_values_except_factor(test_df, poss_delete, row)){
      # mark row for deletion in df
      test_df[poss_delete,]$to_delete <- TRUE
      # remove entry from delete_list
      poss_delete_list <- poss_delete_list[poss_delete_list != poss_delete]
    } 
    
  }
  return_list <- list("test_df"=test_df, "poss_delete_list"=poss_delete_list)
  return(return_list)
}

# Check if the factor row is a duplicate of an omnibus row (=poss_delete)
is_equal_values_except_factor <- function(test_df, poss_delete, row){
  if(test_df[poss_delete,]$effectsize_measure == test_df[row,]$effectsize_measure &
     test_df[poss_delete,]$effectsize_value == test_df[row,]$effectsize_value &
     test_df[poss_delete,]$CI_upper == test_df[row,]$CI_upper &
     test_df[poss_delete,]$CI_lower == test_df[row,]$CI_lower &
     test_df[poss_delete,]$CI_type == test_df[row,]$CI_type &
     test_df[poss_delete,]$test_p_value == test_df[row,]$test_p_value &
     test_df[poss_delete,]$test_id == test_df[row,]$test_id &
     test_df[poss_delete,]$doi == test_df[row,]$doi &
     test_df[poss_delete,]$N == test_df[row,]$N){
    
    if(is.na(test_df[poss_delete,]$effectsize_id)){
      # prevent false positives due to equal p-values <.001 etc. 
      # if there is no info on effectsizes - keep the row
      return(FALSE)
    }else{
      return(TRUE)
    }
  }else{
    return(FALSE)
  }
  
}

# prepare to remove artefacts of double reported factor and main test ES
prep_for_deduplication <- function(test_df){

  poss_delete_list <- list()
  for (row in 1:nrow(test_df)){
    current_test <- test_df[row,]$test_id
    
    if(row == 1){
      # first row in df - it's a new test
      poss_delete_list <- list()
      returnlist <- handle_row_types(test_df, poss_delete_list, row)
      test_df <- returnlist$test_df
      poss_delete_list <- returnlist$poss_delete_list
      
    } else if (current_test != test_df[row-1,]$test_id){
      # new test
      poss_delete_list <- list()
      
      returnlist <- handle_row_types(test_df, poss_delete_list, row)
      test_df <- returnlist$test_df
      poss_delete_list <- returnlist$poss_delete_list
      
    } else {
      # still the same test
      returnlist <- handle_row_types(test_df, poss_delete_list, row)
      test_df <- returnlist$test_df
      poss_delete_list <- returnlist$poss_delete_list
    }
  
  }
  return(test_df)
}


duplicates_marked <- prep_for_deduplication(test_df)

duplicates_removed <- duplicates_marked %>%
  filter(!to_delete) %>%
  select(-to_delete)
summary(duplicates_marked)

write.csv(duplicates_marked, file.path(side_output_path, "factor_duplicates_marked.csv"), row.names=FALSE)

write.csv(duplicates_removed, file.path(clean_data_path, "unified_plausibilitychecked_factorduplicatesremoved_2019-23.csv"), row.names=FALSE)




  
