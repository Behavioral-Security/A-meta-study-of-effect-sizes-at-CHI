# A meta-study of effect sizes at CHI

This repository contains analysis scripts and outputs of the paper **Small, Medium, Large? A Meta-Study of Effect Sizes
at CHI to Aid Interpretation of Effect Sizes and Power Calculation** submitted to CHI'25.

In this read-me, we document the steps to replicate our analysis. Due to size-constraints, this repository does not
contain HTML files needed to run steps 2, 3 and 6, however, we include our outputs of these steps to enable
replication of the following analyses.

We describe the steps for our ground truth comparison at the end of this read-me

## Required software

Python is used for Steps 1, 2, 3, 4, and 6. All requirements are consolidated into a single file located in the Python
folder.

R is used for Steps 5, 7, 8, 9 and 10. Install the necessary R packages using the script provided in Step 0.

## Overview of analysis process

For additional visualization and guidance, see Fig. 1 in the paper

### 0) Install required R packages

We used [renv](https://rstudio.github.io/renv/articles/renv.html) to track packages used in our R analysis. renv.lock
contains the metadata about the necessary packages so they can be re-installed on a new machine.

To initialize this on your machine:
Open the R Project `R.Rproj`
If you do not already have it installed, install renv: `install.packages("renv")`
Call `renv::restore(lockfile="renv.lock")` to install the dependencies

You are now set to use our R Scripts.

### 1)  Download Papers as HTML

Input: Bib files, downloaded from https://dblp.dagstuhl.de/ (e.g. all records
from https://dblp.dagstuhl.de/db/conf/chi/chi2023.html)

Output: CSV of papers with links; downloaded HTML files

Where: `Python / CHI_HTML_download`

Sample Data: `Data / Bibliography-Files`

### 2)  Filter for Quantitative Papers

Input: Downloaded HTML files of (all papers) each year separately in Zip-Format

Output: CSV with info on filter results / quantitativeness of papers

Where: `Python / CHI_quantitativ_filtering`

### 3)  LLM /Langgraph Agent

Input: Prompt (in Supplemental Material); downloaded HTML files of (quantitative) papers

Output: JSON of extracted statistics for each of the analyzed papers + CCS categories and metadata for the papers

Where: `Python / powerpaperparser` (Use main_IDE.py to process multiple papers to also extract CCS categories corresponding to the dois)

### 4)  JSON to CSV

Input: Output of 3)

Output: 1 CSV per year of extracted statistics in flat aka CSV format

Where: `Python / json_to_csv`

### 5)  Unify naming (ES and tests)

Input: Output of 4) ; manual coding necessary (our coded data is in `Data / R_done_manual_check`)

Output: CSV with unified tests and ES for CHI2019 - 23

Where: `R / 03_unify_stuff.R`

### 6)  Plausibility check (do values exist in Html)

Input: HTML Files, Output of 4)

Output: CSVs of extracted statistics in CSV format with information on plausibility checks

Where: `Python / PlausibilityChecker`

### 7)  Merge plausibility check and unified data

Input: Output of 5), Output of 6)

Output: CSV of unified and plausibility-checked data

Where: `R / 04_plausibility_check.R`

### 8)  Removing double-reported data

Input: Output of 7)

Output: Tidied dataset (CSV)

Where: `R / 06_plausibility_check_factors.R`

### 9)  Meta-Analysis

Input: Output of 8)

Output: Images, Tables, the Paper

Where: `R / 07_convert_ES.R`, `R / 08_meta_analysis.R`, `R / 09_effectsize_guidelines.R`, `R / 10_visualization.R`


## Ground Truth Comparison

The ground-truth comparison is implemented in R, with scripts in the R folder.

### Step 1: Sample for ground truth

Input: List of CHI papers as csv files per year of CHI

Output: CSV file of sample for ground truth

Where: `R / 01_sample_for_ground_truth.R`

### Step 2: Get LLM Sample

Run 3) and 4) of **Overview of analysis process** above, only on the selected sample.

### Step 3: Get Human Sample

Manually analyze and annotate the CHI papers, as described in the paper, to extract relevant statistics from them.
If annotating in a JSON format, run 4) of **Overview of analysis process** to get both LLM and human sample in the same
CSV format.

### Step 4: Prepare for Ground Truth Comparison

Input: CSV files of LLM and Human extracted statistics, ods file of progress notes of manual extraction

Output: human ground truth csv with additional columns to be used in manual comparison

Where: `R / 02_prep_groundtruth_comparison.R`

### Step 5: Compare Human and LLM Extracted Data

Input: Output from 4

Output: annotated CSV file

Where: Manual work, where you cross-check which of the LLM extracted data is present in the human data, which is missing
and which was hallucinated. In our manual analysis we focused on the values we would use in the meta analysis later.

### Step 6: Evaluate Comparison

Input: Output from 5

Output: Evaluation results

Where: `R / 05_evaluate_groundtruth.R`


