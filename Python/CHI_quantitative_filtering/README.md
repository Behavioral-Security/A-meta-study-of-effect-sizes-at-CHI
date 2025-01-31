# CHI Paper Quantitative Filtering Script

- Zip the downloaded HTML files (file structure in the zip does not matter).
- Choose the sample size at the top of the script.
- (Optionally) set a fixed random seed — or delete the line where it is set.
- Set the folder where the zip files are located at the bottom of the script.
- Run the script.
- The filter results will be in the respective CSV.
- The headers (`['Paper', "one_true", 'p_val', "p - val_str", "CI", "bayes", 'Ground Truth']`) show the paper
  identifier, if any filter classified it as a quantitative paper, and the individual results from the filters.
- Filters:
    - p_val (`p_filter`) : Searches for occurrences of p </>/=
    - p - val_str (`p_val_filter`) : Searches for occurrences of the "p-val" string
    - CI (`ci_filter`) : Searches for occurrences of the "confidence interval" string
    - bayes (`bayesian_filter`) : Searches for occurrences of the "bayes factor" string

## *Optional:* Accuracy Tester
- copy the files from Data/list_of_gt_CHI_papers to this folder 
- run the script to see which rows matched