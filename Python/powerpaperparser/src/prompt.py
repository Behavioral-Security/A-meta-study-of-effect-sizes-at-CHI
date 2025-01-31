"""this generates the prompt for the powerpaper agent"""


def get_persona_desc() -> str:
    """A personal role of the agent"""
    return """
You are a statistics expert and want to conduct a meta-analysis based on the results of scientific papers. To do this, you need to extract important statistics from the tests reported in the scientific paper.

"""


def get_system_prompt() -> str:
    """get the prompt that can be used as system prompt including persona"""
    return f"""
{get_persona_desc()}
Carefully heed the user's instructions.
Respond using Markdown.
    """


def get_es_knowledge() -> str:
    """not currently in use as adding it to the prompt did not improve extraction"""
    return """
Odds Ratio (OR)
Risk Ratio (RR)

Chi-squared Test Specific:
Phi (For 2x2 tables)
Cramer’s V (For larger tables)
Tschuprow’s T
Cohen’s w

For Larger Tables:
Pearson’s C
Cohen’s g
Cohen’s d
Hedges’ g
Glass’ delta
Point Biserial Correlation Coefficient (Coef.)
Biserial Correlation Coefficient
Rank Biserial Correlation Coefficient

Repeated Measures and Variants:
Cohen’s dz / d(z)
d (rm) (Repeated measures)
Becker’s d (using control condition for standardization)
d(av) (using average variance)
d(r) (using residual variance)

Correlation Coefficients and Related Measures:
Tau
Rho
Pearson’s r
R squared (Coefficient of Determination)
Kendall’s W

ANOVA and Regression Specific:
Eta Squared
Partial Eta Squared
Generalized Eta Squared
Omega Squared
Epsilon Squared
Adjusted Eta Squared
Cohen’s f
Rank-epsilon-squared
Rank-eta-squared
Standardized Coefficients (for each involved factor)
R-squared (for omnibus tests)
Adjusted R-squared
Cohen’s f-squared

Additional Variants and Considerations:
Nagelkerke’s R-squared
Cox-and-Snell R-squared
"""


def get_task_agent(title: str, abstract: str, section_index: str, table_index: str) -> str:
    """Get the task for the agent"""
    return f"""
You need to extract the number of participants in the study, i.e. the sample size.
For tests in the null hypothesis statistical testing paradigma, you need the following information for each individual test:
- the name of the hypothesis test
- the p-value, which can take on numeric values between 0 and 1 and is often denoted as being smaller < or larger > than a given value
- the effect size, which is a different measure depending on the hypothesis test used, and consists of a measure, sometimes denoted by a Greek letter and the actual numeric effect size value
- confidence intervals around the effect size, which consist of two numeric values, one smaller than the effect size and one larger than the effect size. Confidence intervals can be different types, with 95% confidence intervals being the most common. They are frequently abbreviated CI
- the number of participants whose data was used in this test. This will often be same as the sample size in the study, but not always. E.g. in post-hoc tests for independent samples, only the participants in the conditions compared in the post-hoc tests are relevant for those post-hoc tests. Or when only participants who fulfill a certain condition are considered for an analysis.

Depending on the type of test, you need to extract additional information.
Some tests will report multiple different effect sizes. You need to extract them all and if available, their confidence intervals.
Some tests, like regression analyses, will report multiple p-values and corresponding effect sizes and confidence intervals, for each factor involved in the analysis. You need to collect the information for each factor separately, but it should still be identifiable to which test the factor belongs.
Some tests, like analyses of variance (ANOVAs) will report results (i.e. p-values, corresponding effect sizes and confidence intervals) separately for one or more main effects and one or more interaction effects. You need to collect the information for each effect separately, but it should still be identifiable to which test the factor belongs.

A combination of these is also possible, so that a test can have a p-value, effect sizes and confidence intervals associated with the test in general, also called omnibus test, and additional p-values, effect sizes and confidence intervals associated with each individual factor and effect in the test.

Any of the numeric values, such as p-values, effect sizes or confidence intervals can be missing. Sometimes these values are not stated explicitly for each test, e.g. tests with the same result may be summarized e.g. as: "All other comparisons were not significant". In that case, it is necessary to identify how many tests were conducted in total, e.g. by comparing how many conditions there are in total and how many are not yet accounted for by the reporting. Then list each non-significant test separately. If the numeric values cannot be extrapolated from the context, they should be considered missing and you need to state explicitly that the value is missing.

Other values (like names of hypothesis tests) may also be missing, in which case determine the value from the context as best as you can. Test statistics or descriptions in the method section, regarding the used tests in the data analysis or the study set-up (e.g. to determine whether repeated measures analyses were likely used, or which types of variables were measured) can be helpful.

Some values are only reported in tables. If the table's title or a reference in the text suggests relevant information in the table request it via the tool!

If the paper reports tests in a different statistical paradigm, e.g. using Bayes statistics, you also need information for each individual test:
- the name of the hypothesis test
- all other statistics associated with this hypothesis test, including names and values of the statistics

The paper you have to analyze has the title "{title}".
Its abstract is the following:
```
{abstract}
```
It has the following sections:
```
{section_index}
```
And the following tables:
```
{table_index}
```
Analyze the paper using your tools and make sure to report every test with its parameters.
Remember to also report effect sizes that are not explicitly stated including but not limited to:
- correlation coefficients.
- Odds Ratio (OR)
- Risk Ratio (RR)
- Related Measures

After extracting the information for a test (test name, effect size, amount participants, ...), **use the `report` tool immediately** to submit the test. Once the report is submitted, confirm with 'Report submitted' before proceeding to the next test.
Do not move forward until you have completed the report.

After reviewing the sections, have a look at the relevant tables.
"""


def get_prompt(title: str, abstract: str, section_index: str, table_index: str, include_persona=True):
    """get the prompt for the powerpaper agent"""
    return f"""
{get_persona_desc() if include_persona else ''}
{get_task_agent(title, abstract, section_index, table_index)}
"""
