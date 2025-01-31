This folder contains datasets after being manually checked for a certain aspect. Don't delete files in here, since they cannot be generated from Scripts, but work would have to be manually redone.

check_test_es_consistency
	An author went through to check for cases with uncertainty, whether the test fit with the reported effect size.


compare_from_human_done2
	Used for groundtruth comparison (AI vs. human generated groundtruth). 
The first columns contain the human generated groundtruth, one row per effectsize (if no effect size, then one row per test). 
The columns after that contain the results of the manual comparison with the AI extracted data for the groundtruth papers. For different criteria (i.e. test_name_correct etc.) 1 represents that this was present and correct in the AI data, 0 represents explicitly not present or wrong in the AI data, 0.5 partially correct in the AI data and if a cell is empty, then whether the info is present/correct or not can be inferred, e.g. from the value of the fully_correct column. 
added_info contains notes which explain if the AI data contains additional data not in the human data, which is often not what should be reported for a test/not relevant, but can be identified as such by a human. 
Missing =1 means that the whole row does not have an equivalent in the AI data, 
double.reported=1 means that the info is reported multiple times by the AI, often this concerns the first factor within a test, which is reported twice - this is only marked on one of these rows (so it can be filtered out later), 
format-error=1 if the correct info is there, but not formatted correctly, e.g. multiple p-values reported not separately, 
problem_reason contains reasons and explanation about any incorrect or wrongly formatted info

effectsizes3 
	An author went through the list of effect sizes to make note of the ones which can be used in the meta analysis

effectsizes_measures 
	An author went through the list of effect size to unify those which were deemed interesting earlier, so effect size measures referring to the same type of ES have the same name in the dataset

plausibility_check_es_not_found_done

plausibility_check_n_not_found_done

test_names_19_23 
	An author when through the list of test names to unify them, so test names referring to the same type of hypothesis test also have the same name in the dataset