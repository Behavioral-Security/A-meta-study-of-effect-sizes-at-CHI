#----------------------------------------------------------------------------
#
# This script unifies test names and effect size measure names, so that all 
# those representing the same measure are also named the same. 
# This requires manual input. 
# The script formats files so manual checking is more straightforward. 
# The results after the manual checks are in the folder R_done_manual_check.
#
#----------------------------------------------------------------------------

general_data_path <- file.path("..", "Data")
todo_manual_path <- file.path(general_data_path, "R_todo_manual_check")
done_manual_check_path <- file.path(general_data_path, "R_done_manual_check")
side_output_path <- file.path(general_data_path, "R_side_output_data")
clean_data_path <- file.path(general_data_path, "R_clean_data")


library(tidyverse)
source("00_utility_functions.R")

df <- read_all_years_csv() %>%
  mutate(test_name = trimws(test_name)) %>%
  mutate(test_name = tolower(test_name)) #%>%
  unique()
  
df_unique <- df %>% select(doi, year) %>% unique() %>% mutate(
  doi = as.factor(doi)
)

double_reported <- df_unique %>% filter(doi %in% c("10.1145/3313831.3376154", "10.1145/3313831.3376157", "10.1145/3313831.3376707", "10.1145/3491102.3517734"))
write.csv(double_reported, file.path(side_output_path, "more_double_reported_paper.csv"), row.names=FALSE)

test_names <- df %>%
  select(test_name) %>%
  unique()

write.csv(test_names, file.path(todo_manual_path, "test_names.csv"), row.names=FALSE)

effectsizes <- df %>%
  select(effectsize_measure) %>%
  unique()

write.csv(effectsizes, file.path(todo_manual_path, "effectsizes.csv"), row.names=FALSE)

# TODO manually! 
# Code the test_names (unify names according to Field 2012 as basis)
# Code effect sizes as relevant/not relevant (for meta-analysis)

## test names
rm_tests <- c("mixed MANOVA", 
              "Mixed ANCOVA",
              "mixed art anova",
              "dependant t-test",
              "Friedman's ANOVA",
              "repeated measures ANOVA",
              "mixed ANOVA",
              "Wilcoxon matched-pairs test",
              "Mixed Logistic regression",
              "repeated measures logistic regression",
              "mcnemar's test",
              "ART RM ANOVA",
              "time series analysis",
              "RM MANOVA") %>% 
  tolower()
rm_unclear_tests <- c("T-test",
                      "Wilcoxon test",
                      "odds ratio",
                      "Cohen’s d",
                      "r_squared_adjusted",
                      "unclear",
                      "check ES",
                      "check_test") %>%
  tolower()

not_rm_tests <- c("ANCOVA",
                  "Logistic Regression",
                  "Chi squared test",
                  "Kendall's tau",
                  "Mann-Whitney test",
                  "Kruskal-Wallis test",
                  "independent t-test",
                  "Pearson correlation",
                  "linear regression",
                  "correlation (unspecified)",
                  "ANOVA",
                  "Spearman correlation",
                  "MANOVA",
                  "ART ANOVA",
                  "ordinal logistic regression",
                  "fisher's exact test",
                                    "MANCOVA") %>%
  tolower()

rm_not_applicable_tests <- c("Structural Equation modelling",
                             "regression (different)",
                             "regression (unspecified)",      
                             "mediation analysis",      
                             "factor analysis",
                             "Shapiro-Wilk test",
                             "Equivalence test",
                             "one-sample wilcoxon singed rank test",
                             "One-sample t-test",
                             "Bayesian model",
                             "survival analysis",
                             "moderator analysis",
                             "correlation (different)",
                             "different") %>%
  tolower()

# Did this in steps.
#test_names_done1 <- read.csv(file.path(done_manual_check_path, "test_names1.csv")) %>%
#  select(-is_rm)
#test_names_done <- read.csv(file.path(done_manual_check_path, "test_names2.csv"))
#test_names_done3 <- read.csv(file.path(done_manual_check_path, "test_names3.csv"))
#test_names_done <- rbind(test_names_done1, test_names_done, test_names_done3) #%>%

test_names_done <- read.csv(file.path(done_manual_check_path, "test_names_19-23.csv")) %>%
  mutate(testnames_unified = trimws(testnames_unified)) %>%
  mutate(testnames_unified = tolower(testnames_unified)) %>%
  mutate(testnames_unified = case_when(testnames_unified == "fisher’s exact test" ~ "fisher's exact test",
                                       testnames_unified == "mcnemar’s test" ~ "mcnemar's test",
                                       testnames_unified == "kendall’s tau" ~ "kendall's tau",
                                       TRUE ~ testnames_unified)) %>%
  unique()

only_new_test_names <- test_names_done %>% 
  select(-test_name) %>%
  unique() %>%
  mutate(is_rm = case_when(testnames_unified == "" ~ "unclear test",
                           testnames_unified %in% rm_tests ~ "RM",
                           testnames_unified %in% rm_unclear_tests ~ "unclear",
                           testnames_unified %in% not_rm_tests ~ "not_RM",
                           testnames_unified %in% rm_not_applicable_tests ~ "not_applicable",
                           TRUE ~ ""
                           )) %>%
  unique()
  

test_names_with_rm <- test_names_done %>%
  unique() %>%
  left_join(only_new_test_names, by=c("testnames_unified")) %>%
  mutate(test_name = trimws(test_name)) %>%
  mutate(test_name = tolower(test_name)) %>%
  unique()


## effect sizes

effectsizes_done <- read.csv(file.path(done_manual_check_path, "effectsizes3.csv")) %>%
  mutate(of_interest = as.factor(of_interest))

effectsizes_of_interest <- effectsizes_done %>%
  filter(of_interest %in% c("yes","maybe", "check test")) 

#effectsizes_of_interest <- full_join(effectsizes_of_interest, only_interesting_es) # for integrating prior results

write.csv(effectsizes_of_interest, file.path(todo_manual_path, "effectsizes_measures.csv"), na="", row.names = FALSE)

# TODO manually !!!
# code effect sizes to unified names

only_interesting_es <- read.csv(file.path(done_manual_check_path,"effectsizes_measures3.csv")) 



effectsizes_unified <- full_join(effectsizes_done, only_interesting_es, by=c("effectsize_measure", "of_interest")) %>%
  mutate(of_interest = case_when(of_interest == "" ~ "not_relevant",
                                 TRUE ~ of_interest))


### Add ES + test names back into df

df_unified <- left_join(df, test_names_with_rm, by=c("test_name")) %>%
  left_join(effectsizes_unified, by=c("effectsize_measure")) %>%
  mutate(testnames_unified = as.factor(testnames_unified)) %>%
  mutate(across(c(year, is_rm,
                  effectsize_measure, effectsize_measure_unified, of_interest, specifiers
                  ), as.factor)) 

summary(df_unified$effectsize_measure_unified)
summary(df_unified$testnames_unified)


### manually check some effectsizes, where the test is needed as context
check_tests_for_es <- df_unified %>%
  filter(of_interest == "check test" | testnames_unified == "check es" | effectsize_measure_unified == "check_test" | effectsize_measure_unified== "cor") %>%
  mutate(effectsize_measure_unified = case_when(effectsize_measure_unified == "cor" & testnames_unified == "pearson correlation" ~ "Pearsons_r",
                                                effectsize_measure_unified == "cor" & testnames_unified == "spearman correlation" ~ "spearmans_rho",
                                                effectsize_measure_unified == "cor" & testnames_unified == "kendall's tau" ~ "kendalls_tau",
                                                effectsize_measure_unified == "cor" & testnames_unified == "mann-whitney test" ~ "rank_biserial_r",
                                                effectsize_measure_unified == "cor" & testnames_unified == "independent t-test" ~ "rank_biserial_r",
                                                effectsize_measure_unified == "cor"  ~ "correlation (unspecified)",
                                                effectsize_measure_unified == "cramers_v" & testnames_unified == "chi squared test" ~ "cramers_v",
                                                effectsize_measure_unified == "cramers_v" & testnames_unified == "fisher's exact test" ~ "cramers_v",
                                                effectsize_measure_unified == "cramers_v" ~ "uncertain",
                                                effectsize_measure_unified == "Cohens_d" & grepl("t-test", testnames_unified) ~ "Cohens_d",
                                                effectsize_measure_unified == "Cohens_d" & testnames_unified == "mann-whitney test" ~ "Cohens_d",
                                                effectsize_measure_unified == "Cohens_d" & grepl("wilcoxon", testnames_unified) ~ "Cohens_d",
                                                effectsize_measure_unified == "Cohens_d" ~ "uncertain",
                                                effectsize_measure_unified == "r_squared" ~ "check_manually",
                                                effectsize_measure_unified == "check_test" ~ "check_manually",
                                                effectsize_measure_unified == "eta" ~ "check_manually",
                                                effectsize_measure_unified == "f_squared" ~ "check_manually",
                                                effectsize_measure_unified == "omega_squared" ~ "check_manually",
                                                TRUE ~ effectsize_measure_unified)) %>%
  mutate(effectsize_measure_unified = as.factor(effectsize_measure_unified)) %>%
  select(doi, test_id, effectsize_id, test_name, factor, effectsize_measure, effectsize_value, testnames_unified, is_rm, of_interest, effectsize_measure_unified, specifiers) %>%
  arrange(effectsize_measure_unified)

write.csv(check_tests_for_es, file.path(todo_manual_path, "check_test_es_consistency.csv"), row.names = FALSE)

# TODO manually check which of the ES fit
full_info_from_check_test <- df_unified %>%
  filter(of_interest == "check test" | testnames_unified == "check es") %>%
  select(-effectsize_measure_unified, -specifiers, -is_rm)

checked_test_es_consistency <- read.csv(file.path(done_manual_check_path,"check_test_es_consistency.csv")) %>%
  select(-effectsize_value) %>% # handling in spreadsheet messes things up
  select(-of_interest) %>% left_join(full_info_from_check_test) %>%
  mutate(of_interest = "checked_test") %>%
  mutate(effectsize_measure_unified = as.factor(effectsize_measure_unified))
summary(checked_test_es_consistency$effectsize_measure_unified)
colnames(df_unified_final)

# try out fixing some stuff I missed before
test <- df_unified_final %>% 
  filter(effectsize_measure_unified == "cor" | effectsize_measure_unified == "check_test") %>%
  mutate(effectsize_measure_unified = case_when(testnames_unified == "spearman correlation" ~ "spearmans_rho",
                                                testnames_unified == "correlation (unspecified)" ~ "r_squared",
                                                TRUE ~ "uncertain"))

  
# Merge unified data together
# fix the wrong doi papers
df_unified_final <- df_unified %>%
  filter(of_interest != "check test") %>%
  filter(testnames_unified != "check es") %>%
  rbind(checked_test_es_consistency) %>%
  mutate(to_manipulate = case_when(effectsize_measure_unified == "cor" | effectsize_measure_unified == "check_test" ~ TRUE, 
                                   TRUE ~ FALSE)) %>%
  mutate(effectsize_measure_unified = case_when(to_manipulate & testnames_unified == "spearman correlation" ~ "spearmans_rho",
                                                to_manipulate &testnames_unified == "correlation (unspecified)" ~ "r_squared",
                                                to_manipulate ~ "uncertain",
                                                TRUE ~ effectsize_measure_unified)) %>%
  mutate(effectsize_measure_unified = tolower(effectsize_measure_unified)) %>%
  mutate(effectsize_measure_unified = as.factor(effectsize_measure_unified)) #%>%
  mutate(doi = case_when(doi == "10.1145/3313831.3376346" & topics == "human and societal aspects of security and privacy;security and privacy" ~ "10.1145/3313831.3376651",
                         doi == "10.1145/3313831.3376442" & topics == "text input;human-centered computing" ~ "10.1145/3313831.3376441",
                         doi == "10.1145/3313831.3376457" & topics == "software security engineering;security and privacy;hci design and evaluation methods;human-centered computing" ~ "10.1145/3313831.3376754",
                         doi == "10.1145/3411764.3445708" & topics == "computing methodologies" ~ "10.1145/3411764.3445719",
                         TRUE ~ doi))



summary(df_unified_final)
summary(df_unified_final$effectsize_measure_unified)


# check duplicates from ACM non-unique dois bug
check_dois <- df_unified_final %>% filter(doi %in% c("10.1145/3313831.3376346", "10.1145/3313831.3376442", "10.1145/3313831.3376457",
                                                     "10.1145/3411764.3445708", "10.1145/3290605.3300350")) %>%
  mutate(doi = case_when(doi == "10.1145/3313831.3376346" & topics == "human and societal aspects of security and privacy;security and privacy" ~ "10.1145/3313831.3376651",
         doi == "10.1145/3313831.3376442" & topics == "text input;human-centered computing" ~ "10.1145/3313831.3376441",
         doi == "10.1145/3313831.3376457" & topics == "software security engineering;security and privacy;hci design and evaluation methods;human-centered computing" ~ "10.1145/3313831.3376754",
         doi == "10.1145/3411764.3445708" & topics == "computing methodologies" ~ "10.1145/3411764.3445719",
         TRUE ~ doi))


write.csv(df_unified_final, file.path(clean_data_path,"unified_tests_and_ES_2019-23.csv"), row.names=FALSE)

### Update with new years' data for test names

# some automatic pre-unifying. Not all of this is correct. 
# (sometimes the match is too early) However, it saves work on manual coding.
test_name_not_unified_yet <-  df_unified %>% 
  filter(is.na(testnames_unified)) %>%
  select(test_name) %>%
  mutate(test_name = trimws(test_name)) %>%
  unique() %>%
  mutate(unified_name_proposal = case_when(grepl("student's t-test", test_name) ~ "independent t-test",
                                           grepl("independent means t-test", test_name) ~ "independent t-test",
                                           grepl("independent-samples t-test", test_name) ~ "independent t-test",
                                           grepl("independent samples t-test", test_name) ~ "independent t-test",
                                           grepl("independent sample t-test", test_name) ~ "independent t-test",
                                           grepl("unpaired t-test", test_name) ~ "independent t-test",
                                           grepl("tukey hsd", test_name) ~ "independent t-test",
                                           grepl("tukey's hsd", test_name) ~ "independent t-test",
                                           grepl("tukey's post", test_name) ~ "independent t-test",
                                           grepl("tukey pairwise", test_name) ~ "independent t-test",
                                           grepl("games howell post", test_name) ~ "independent t-test",
                                           grepl("pairwise tukey", test_name) ~ "independent t-test",
                                           grepl("dunnet's test", test_name) ~ "independent t-test",
                                           grepl("two-sample t-test", test_name) ~ "independent t-test",
                                           grepl("Welch's t-test", test_name) ~ "independent t-test",
                                           grepl("welch two sample t-test", test_name) ~ "independent t-test",
                                           grepl("independent t-test", test_name) ~ "independent t-test",
                                           grepl("between-subjects t-test", test_name) ~ "independent t-test",
                                           grepl("Welch's unequal variances t-test", test_name) ~ "independent t-test",
                                           grepl("t-test for independent groups", test_name) ~ "independent t-test",
                                           grepl("paired-samples t-test", test_name) ~ "dependant t-test",
                                           grepl("paired samples t-test", test_name) ~ "dependant t-test",
                                           grepl("paired sample t-test", test_name) ~ "dependant t-test",
                                           grepl("paired-sample t-test", test_name) ~ "dependant t-test",
                                           grepl("paired t-test", test_name) ~ "dependant t-test",
                                           grepl("dependent t-test", test_name) ~ "dependant t-test",
                                           grepl("art rm-anova", test_name) ~ "art rm anova",
                                           grepl("art rm anova", test_name) ~ "art rm anova",
                                           grepl("friedman test", test_name) ~ "friedman's anova",
                                           grepl("friedman rank sum", test_name) ~ "friedman's anova",
                                           grepl("friedman ranked sum", test_name) ~ "friedman's anova",
                                           grepl("friedman analysis", test_name) ~ "friedman's anova",
                                           grepl("friedman's test", test_name) ~ "friedman's anova",
                                           grepl("friedman's anova", test_name) ~ "friedman's anova",
                                           grepl("mcnemar's test", test_name) ~ "mcnemar's test",
                                           grepl("cochran's q test", test_name) ~ "mcnemar's test",
                                           grepl("mcnemar", test_name) ~ "mcnemar's test",
                                           grepl("wilcoxon signed-rank", test_name) ~ "wilcoxon matched-pairs test",
                                           grepl("wilcoxon sign rank test", test_name) ~ "wilcoxon matched-pairs test",
                                           grepl("wilcoxon-pratt signed ranks test", test_name) ~ "wilcoxon matched-pairs test",
                                           grepl("wilcoxon signed rank", test_name) ~ "wilcoxon matched-pairs test",
                                           grepl("wilcoxon signed rank-test", test_name) ~ "wilcoxon matched-pairs test",
                                           grepl("wilcoxon signed-ranks", test_name) ~ "wilcoxon matched-pairs test",
                                           grepl("wilcoxon rank paired-test", test_name) ~ "wilcoxon matched-pairs test",
                                           grepl("mixed anova", test_name) ~ "mixed anova",
                                           grepl("mixed-model anova", test_name) ~ "mixed anova",
                                           grepl("way mixed anova", test_name) ~ "mixed anova",
                                           grepl("mixed factorial anova", test_name) ~ "mixed anova",
                                           grepl("mixed analysis of variance", test_name) ~ "mixed anova",
                                           grepl("mixed-factorial anova", test_name) ~ "mixed anova",
                                           grepl("mixed-design anova", test_name) ~ "mixed anova",
                                           grepl("mixed design repeated measures anova", test_name) ~ "mixed anova",
                                           grepl("rm-anova", test_name) ~ "repeated measures anova",
                                           grepl("repeated measure anova", test_name) ~ "repeated measures anova",
                                           grepl("repeated-measure analysis of variance", test_name) ~ "repeated measures anova",
                                           grepl("repeated measures anova", test_name) ~ "repeated measures anova",
                                           grepl("repeated-measures anova", test_name) ~ "repeated measures anova",
                                           grepl("within-subject anova", test_name) ~ "repeated measures anova",
                                           grepl("within subject anova", test_name) ~ "repeated measures anova",
                                           grepl("within-subjects anova", test_name) ~ "repeated measures anova",
                                           grepl("within subjects anova", test_name) ~ "repeated measures anova",
                                           grepl("repeated measures analysis of variance", test_name) ~ "repeated measures anova",
                                           grepl("rm anova", test_name) ~ "repeated measures anova",
                                           grepl("logistic mixed model", test_name) ~ "mixed logistic regression",
                                           grepl("time-series analysis", test_name) ~ "time-series analysis",
                                           grepl("manova with repeated measures", test_name) ~ "rm manova",
                                           grepl("repeated measures multivariate analysis of variance", test_name) ~ "rm manova",
                                           grepl("rm-manova", test_name) ~ "rm manova",
                                           grepl("rm manova", test_name) ~ "rm manova",
                                           grepl("ancova", test_name) ~ "ancova",
                                           grepl("art anova", test_name) ~ "art anova",
                                           grepl("aligned-rank transform anova", test_name) ~ "art anova",
                                           grepl("aligned rank transform anova", test_name) ~ "art anova",
                                           grepl("art-anova", test_name) ~ "art anova",
                                           grepl("anova with art", test_name) ~ "art anova",
                                           grepl("align-and-rank anova", test_name) ~ "art anova",
                                           grepl("anova with aligned rank transform", test_name) ~ "art anova",
                                           grepl("kruskal-wallis h test", test_name) ~ "kruskal-wallis test",
                                           grepl("kruskal-wallis h-test", test_name) ~ "kruskal-wallis test",
                                           grepl("kruskal-wallis anova", test_name) ~ "kruskal-wallis test",
                                           grepl("kruskal-wallis test", test_name) ~ "kruskal-wallis test",
                                           grepl("kruskal-wallis rank sum test", test_name) ~ "kruskal-wallis test",
                                           grepl("kruskal-wallis", test_name) ~ "kruskal-wallis test",
                                           grepl("χ2 test", test_name) ~ "chi squared test",
                                           grepl("chi-square test", test_name) ~ "chi squared test",
                                           grepl("chi-squared test", test_name) ~ "chi squared test",
                                           grepl("chi-square goodness-of-fit test", test_name) ~ "chi squared test",
                                           grepl("χ2 goodness-of-fit test", test_name) ~ "chi squared test",
                                           grepl("χ² test", test_name) ~ "chi squared test",
                                           grepl("chi-square goodness of fit test", test_name) ~ "chi squared test",
                                           grepl("kendall's tau-b", test_name) ~ "kendall's tau",
                                           grepl("kendall's tau", test_name) ~ "kendall's tau",
                                           grepl("kendall's τb correlation", test_name) ~ "kendall's tau",
                                           grepl("kendall's rank correlation", test_name) ~ "kendall's tau",
                                           grepl("pearson's correlation", test_name) ~ "pearson correlation",
                                           grepl("pearson correlation", test_name) ~ "pearson correlation",
                                           grepl("pearson's product-moment correlation", test_name) ~ "pearson correlation",
                                           grepl("pearson's bivariate correlation", test_name) ~ "pearson correlation",
                                           grepl("pearson's r", test_name) ~ "pearson correlation",
                                           grepl("spearman's ρ test", test_name) ~ "spearman correlation",
                                           grepl("spearman rho", test_name) ~ "spearman correlation",
                                           grepl("spearman's rho", test_name) ~ "spearman correlation",
                                           grepl("spearman's rank correlation", test_name) ~ "spearman correlation",
                                           grepl("spearman rank correlation", test_name) ~ "spearman correlation",
                                           grepl("spearman's ranked correlation", test_name) ~ "spearman correlation",
                                           grepl("spearman rank-order", test_name) ~ "spearman correlation",
                                           grepl("spearman's rank-order", test_name) ~ "spearman correlation",
                                           grepl("spearman correlation", test_name) ~ "spearman correlation",
                                           grepl("spearman's correlation", test_name) ~ "spearman correlation",
                                           grepl("fisher's exact test", test_name) ~ "fisher's exact test",
                                           grepl("fisher exact test", test_name) ~ "fisher's exact test",
                                           grepl("multiple linear regression", test_name) ~ "linear regression",
                                           grepl("linear regression", test_name) ~ "linear regression",
                                           grepl("multiple regression", test_name) ~ "linear regression",
                                           grepl("ols regression", test_name) ~ "linear regression",
                                           grepl("brunner munzel", test_name) ~ "mann-whitney test",
                                           grepl("dunn's pairwise test", test_name) ~ "mann-whitney test",
                                           grepl("dunn test", test_name) ~ "mann-whitney test",
                                           grepl("wilcoxon-mann-whitney test", test_name) ~ "mann-whitney test",
                                           grepl("mann-whitney u", test_name) ~ "mann-whitney test",
                                           grepl("mann-whitney wilcoxon test", test_name) ~ "mann-whitney test",
                                           grepl("mann-whitney-wilcoxon", test_name) ~ "mann-whitney test",
                                           grepl("mann-whitney test", test_name) ~ "mann-whitney test",
                                           grepl("wilcoxon rank sum", test_name) ~ "mann-whitney test",
                                           grepl("wilcoxon rank-sum", test_name) ~ "mann-whitney test",
                                           grepl("mann-whitney's u", test_name) ~ "mann-whitney test",
                                           grepl("rank-sum test", test_name) ~ "mann-whitney test",
                                           grepl("ordinal logistic regression", test_name) ~ "ordinal logistic regression",
                                           grepl("ordinal regression", test_name) ~ "ordinal logistic regression",
                                           grepl("logistic regression", test_name) ~ "logistic regression",
                                           grepl("multivariate analysis of variance", test_name) ~ "manova",
                                           grepl("manova", test_name) ~ "manova",
                                           grepl("multivariate anova", test_name) ~ "manova",
                                           grepl("anova for independent samples", test_name) ~ "anova",
                                           grepl("analysis of variance", test_name) ~ "anova",
                                           grepl("anova", test_name) ~ "anova",
                                           grepl("odds ratio", test_name) ~ "odds ratio",
                                           grepl("Cohen's d", test_name) ~ "cohen’s d",
                                           grepl("mediation analysis", test_name) ~ "mediation analysis",
                                           grepl("moderator analysis", test_name) ~ "mediation analysis",
                                           grepl("structural equation modeling", test_name) ~ "structural equation modelling",
                                           grepl("structural equation model", test_name) ~ "structural equation modelling",
                                           grepl("sem model", test_name) ~ "structural equation modelling",
                                           grepl("(sem)", test_name, fixed=TRUE) ~ "structural equation modelling",
                                           grepl("factor analysis", test_name) ~ "factor analysis",
                                           grepl("test of equivalence", test_name) ~ "equivalence test",
                                           grepl("equivalence testing", test_name) ~ "equivalence test",
                                           grepl("(tost)", test_name) ~ "equivalence test",
                                           grepl("shapiro-wilk", test_name) ~ "shapiro-wilk test",
                                           grepl("bayesian", test_name) ~ "bayesian model",
                                           grepl("one-sample wilcoxon signed", test_name) ~ "one-sample wilcoxon singed rank test",
                                           grepl("1-sample nonparametric wilcoxon signed", test_name) ~ "one-sample wilcoxon singed rank test",
                                           grepl("one-sample t-test", test_name) ~ "one-sample t-test",
                                           grepl("1-sample t-test", test_name) ~ "one-sample t-test",
                                           grepl("one sample t-test", test_name) ~ "one-sample t-test",
                                           grepl("1 sample t-test", test_name) ~ "one-sample t-test",
                                           grepl("repeated measures correlation", test_name) ~ "correlation (different)",
                                           grepl("survival analysis", test_name) ~ "survival analysis",
                                           grepl("linear mixed effects", test_name) ~ "regression (different)",
                                           grepl("linear mixed-effects", test_name) ~ "regression (different)",
                                           grepl("linear mixed effect", test_name) ~ "regression (different)",
                                           grepl("(lme) model", test_name) ~ "regression (different)",
                                           grepl("binomial regression", test_name) ~ "regression (different)",
                                           grepl("linear model", test_name) ~ "regression (different)",
                                           grepl("multilevel model", test_name) ~ "regression (different)",
                                           grepl("poisson mixed model", test_name) ~ "regression (different)",
                                           grepl("multilevel regression", test_name) ~ "regression (different)",
                                           grepl("hierarchical linear regression", test_name) ~ "regression (different)",
                                           grepl("multiple regression analysis", test_name) ~ "regression (different)",
                                           grepl("hierarchical logistic model", test_name) ~ "regression (different)",
                                           grepl("general linear model", test_name) ~ "regression (different)",
                                           grepl("hierarchical regression", test_name) ~ "regression (different)",
                                           grepl("polynomial regression", test_name) ~ "regression (different)",
                                           grepl("cox regression", test_name) ~ "regression (different)",
                                           grepl("poisson regression", test_name) ~ "regression (different)",
                                           grepl("quadratic mixed model", test_name) ~ "regression (different)",
                                           grepl("random-effect linear regression", test_name) ~ "regression (different)",
                                           grepl("logit regression", test_name) ~ "regression (different)",
                                           grepl("logit mixed effect regression", test_name) ~ "regression (different)",
                                           grepl("cubic regression", test_name) ~ "regression (different)",
                                           grepl("nomial logit model", test_name) ~ "regression (different",
                                           grepl("cumulative link mixed model", test_name) ~ "regression (different)",
                                           grepl("random effects logistic model", test_name) ~ "regression (different)",
                                           
                                           
                                           
                                           TRUE ~ "")) %>%
  
  mutate(unified_name_proposal = as_factor(unified_name_proposal))
  
write.csv(test_name_not_unified_yet, file.path(todo_manual_path,"test_names4.csv"), row.names = FALSE)

# check progress and get ideas for filtering
summary(test_name_not_unified_yet$unified_name_proposal)
df_unified %>% filter(testnames_unified == "regression (different)") %>% pull(test_name)
rm_not_applicable_tests

