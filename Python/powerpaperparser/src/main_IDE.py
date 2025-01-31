"""Main of PowerPaperParser Agent"""
import json
import os
from pathlib import Path

from langgraph.errors import GraphRecursionError
from minimal_CCS_extraction import get_header
from power_paper_parser_agent import PowerPaperParserAgent
from power_paper_parser_agent import PowerPaperParserAgentContext

def start_agent(path: Path, result_path: Path) -> list:
    """Function to run the agent"""
    context = PowerPaperParserAgentContext(
        paperPath=path,
        result=[],
        result_path=result_path
    )
    agent = PowerPaperParserAgent()

    try:
        context = agent.run(context)

    except GraphRecursionError as e:
        print(f"{e}")

    return context.result


def run_agent(html_path: Path, results_folder=Path(__file__).parent.parent / 'results'):
    """The run function!"""
    # Extract the name of the HTML file
    html_filename = html_path.name
    # Create the results folder if it doesn't exist
    results_folder.mkdir(parents=True, exist_ok=True)
    # Define the path to the results txt file
    result_txt_path = results_folder / f"{html_filename[:-5]}.json"

    # acquire results
    result = start_agent(html_path, results_folder / f"{html_filename[:-5]}.md")
    # get header and ccs
    ccs_header = get_header(html_path)
    # merge the two
    ccs_header.update({"tests": result})
    # dump the result into a json file
    with open(result_txt_path, 'w', encoding="utf-8") as json_file:
        json.dump(ccs_header, json_file, indent=4)


if __name__ == "__main__":
    from settings import *

    api_key_file = Path(__file__).parent.parent / "OPENAI_API_KEY"
    if api_key_file.exists():
        with open(Path(__file__).parent.parent / "OPENAI_API_KEY", 'r') as file:
            OPENAI_API_KEY = file.read()
        os.environ["OPENAI_API_KEY"] = OPENAI_API_KEY

    for paper in papers:
        if os.path.isfile(Path(__file__).parent.parent / "results" / (paper[:-5] + ".json")):
            continue
        print("Starting Agent for Paper:", paper)
        run_agent(Path(html_folder_path + "/" + paper))
