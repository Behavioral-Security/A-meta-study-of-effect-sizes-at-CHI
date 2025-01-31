"""Jazzer agent."""

from pathlib import Path
from typing import Any
from typing import Callable
from typing import Literal

# https://python.langchain.com/v0.2/docs/integrations/tools/filesystem/
from langchain_core.messages import AIMessage
from langchain_core.messages import HumanMessage
from langchain_core.messages import SystemMessage
from langchain_core.messages import ToolMessage
from langchain_core.runnables.config import RunnableConfig
from langchain_core.tools import BaseTool
from langgraph.graph import StateGraph
from pydantic import BaseModel

from agent_base import BaseAgent
from chat_agent_base import BaseChatState
from chat_agent_base import CallModelNode
from chat_agent_base import ToolExecutorNode
from paper_parser import PaperParser
from powerpaperparser_agent_tools import ReportTestTool, TableReadTool
from powerpaperparser_agent_tools import SectionReadTool
from prompt import get_prompt
from prompt import get_system_prompt


class PowerPaperParserAgentContext(BaseModel):
    """Context for the Jazzer agent."""

    paperPath: Path
    result: list[dict[Any, Any]]
    result_path: Path


class AgentState(BaseChatState):
    """State for the Jazzer agent."""


def from_model_to(state: AgentState) -> Literal["run_tool", "__end__"]:
    """Router function to decide which node to go to next."""
    last_message = state.messages[-1]
    if isinstance(last_message, AIMessage) and last_message.tool_calls:
        return "run_tool"

    return "__end__"


def from_tool_to(state: AgentState) -> Literal["call_model", "__end__"]:
    """Ends if write_final_dictionary was called"""
    last_message = state.messages[-1]
    if isinstance(last_message, ToolMessage):
        if last_message.name == "write_final_dictionary":
            return "__end__"

    return "call_model"


class PowerPaperParserAgent(BaseAgent[PowerPaperParserAgentContext]):
    """
    Analyze project and create dictionary for Fuzzer.
    """

    @staticmethod
    def run(ctx: PowerPaperParserAgentContext, recursion_limit=300, temperature=0) -> PowerPaperParserAgentContext:
        pp = PaperParser(ctx.paperPath)
        reporttool = ReportTestTool()

        tools: list[BaseTool | Callable] = [SectionReadTool(paperparser=pp), TableReadTool(paperparser=pp), reporttool]

        # definition of nodes
        call_model = CallModelNode(model_name="gpt-4o", temperature=temperature, tools=tools)
        run_tool = ToolExecutorNode(tools)

        # topology of graph
        graph = StateGraph(AgentState)
        graph.add_node("call_model", call_model)
        graph.add_node("run_tool", run_tool)

        graph.add_conditional_edges("call_model", from_model_to)
        graph.add_conditional_edges("run_tool", from_tool_to)

        graph.set_entry_point("call_model")

        runnable = graph.compile()

        init_state = AgentState(
            messages=[
                SystemMessage(content=get_system_prompt()),
                HumanMessage(
                    content=get_prompt(title=pp.get_title(), abstract=pp.get_abstract(),
                                       section_index=pp.get_section_index(), table_index=pp.get_table_index())
                ),
            ]
        )

        print(init_state.messages[-1])

        PowerPaperParserAgent.run_and_report_output(
            runnable,
            init_state,
            config=RunnableConfig(recursion_limit=recursion_limit),
            md_file_name=ctx.result_path
        )

        ctx.result = reporttool.tests

        return ctx
