"""tools implemented for the jazzer agent"""

from langchain.pydantic_v1 import BaseModel
from langchain_core.tools import BaseTool
from pydantic.v1 import Field
from typing import List, Optional

from paper_parser import PaperParser


class SectionReadTool(BaseTool):
    """Tool to read a section or sub section from a paper."""

    class Args(BaseModel):
        """Arguments for the SectionReadTool."""

        index: str = Field(description="The index of the section or subsection you want to read.")

    name: str = "read_section"
    description: str = """Provides the text of a section or subsection of a paper.
Specify which section by using the index argument."""
    args_schema: type[BaseModel] = Args

    paperparser: PaperParser

    # pylint: disable=arguments-differ
    def _run(self, index: str) -> str:
        """Internal run method"""
        try:
            return self.paperparser.get_section_text_by_index(index)
        except ValueError as e:
            print(e)
        try:
            return self.paperparser.get_section_text_by_title(index)
        except ValueError as e:
            print(e)

        return "Could not find section."


class ConfidenceInterval(BaseModel):
    """Confidence Interval structure."""
    lower: str = Field(description="The lower bound of the confidence interval.")
    upper: str = Field(description="The upper bound of the confidence interval.")
    CI_type: str = Field(description="The type of the confidence interval.")


class EffectSize(BaseModel):
    """Effect Size structure."""
    effectsize_measure: str = Field(description="The measure of the effect size.")
    value: str = Field(description="The value of the effect size.")
    CI: ConfidenceInterval


class Factor(BaseModel):
    """Factor structure."""
    factor: str = Field(description="The name of the factor.")
    p_value: str = Field(description="The p-value associated with the factor.")
    effectsizes: List[EffectSize] = Field(description="List of effect sizes associated with the factor.")


class ReportTestArgs(BaseModel):
    """Arguments for the report test tool."""
    test_name: str = Field(description="The full name of the statistic test.")
    test_N: str = Field(description="The number of participants.")
    num_conditions: str = Field(
        description="The number of conditions in the test. Report it the exactly as in the text.")
    p_value: str = Field(description="The p value of the test.")
    effectsizes: List[EffectSize] = Field(description="List of effect sizes.")
    factors: Optional[List[Factor]] = Field(default=[],
                                            description="List the factors for each condition in the statistical test.")


class ReportTestTool(BaseTool):
    """Tool to report statistic test data."""

    name: str = "report_test"
    description: str = (
        """Reports a test. If you don't have a value for a field, submit UNKNOWN as the value."""
    )

    args_schema: type[BaseModel] = ReportTestArgs
    tests: List[dict] = []

    # pylint: disable=arguments-differ
    def _run(
            self,
            test_name,
            test_N,
            num_conditions,
            p_value,
            effectsizes,
            factors=None
    ) -> str:
        result = {
            "test_name": test_name,
            "N": test_N,
            "num_conditions": num_conditions,
            "p_value": p_value,
            "effectsizes": [es.dict() for es in effectsizes],
        }

        if factors:
            result["factors"] = [factor.dict() for factor in factors]

        self.tests.append(result)
        return "Test report successful"


class TableReadTool(BaseTool):
    """Tool to read a Table from a paper."""

    class Args(BaseModel):
        """Arguments for the SectionReadTool."""

        index: str = Field(description="The index of the table you want to read.")

    name: str = "read_table"
    description: str = """Provides the csv code for a table from a research paper.
Specify which table by using the index argument."""
    args_schema: type[BaseModel] = Args

    paperparser: PaperParser

    # pylint: disable=arguments-differ
    def _run(self, index: str):
        print("table_read with index", index)
        """Internal run method"""
        try:
            table_title, csv_code = self.paperparser.get_table_by_index(index)
            table_prompt = """You will be processing the table row by row. For each row, you need to extract the information as told in the first prompt:
                           After extracting all this information for one row, use the `report` tool to report the results, and only after that, proceed to the next row. Do not extract information for multiple rows at once. 
                           It is very important to include non-significant results if they have effect sizes.
                           The title of the table is: """ + table_title
            message = table_prompt + "\nAnd here is the table as CSV: \n" + csv_code
            return message
        except ValueError as e:
            print(e)

        return "Could not find table."
