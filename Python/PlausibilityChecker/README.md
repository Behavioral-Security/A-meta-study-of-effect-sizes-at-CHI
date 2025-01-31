# SanityChecker script

Checks if values reported by the LLM are present in the paper.

Usage:

```
python3 PlausibilityChecker.py <input_csv> <output_csv> <paper_dir>
```

- Sample input would be in Data/extracted_data.
- Sample output would be in Data/extracted_data/plausbility_checked.

- `paper_dir` is supposed to be a folder with subfolder of each year in which the HTMLs of the papers are present.
