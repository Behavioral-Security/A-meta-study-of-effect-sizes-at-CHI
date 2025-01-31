"""Main of PowerPaperParser Agent"""

import sys
from pathlib import Path

from langgraph.errors import GraphRecursionError

from power_paper_parser_agent import PowerPaperParserAgent
from power_paper_parser_agent import PowerPaperParserAgentContext


def start_agent(path: Path) -> list:
    """Function to run the agent"""
    context = PowerPaperParserAgentContext(
        paperPath=path,
        result=[],
    )
    agent = PowerPaperParserAgent()

    try:
        context = agent.run(context)

    except GraphRecursionError as e:
        print(f"{e}")

    return context.result


def run_agent():
    "The run function!"

    if len(sys.argv) < 2:
        print("Usage: run_ppp $PATH_TO_HTML")
        return

    result = start_agent(Path(sys.argv[1]))
    print(result)


if __name__ == "__main__":
    run_agent()
