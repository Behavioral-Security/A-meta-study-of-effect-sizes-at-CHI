"""Baseclass for all gents managed by CRS."""

import datetime
import json
import os
from abc import abstractmethod
from pathlib import Path
from typing import Generic
from typing import TypeVar

from langchain_core.messages import AIMessage
from langchain_core.messages import BaseMessage
from langchain_core.messages import ToolMessage
from langchain_core.runnables.config import RunnableConfig
from langgraph.graph.graph import CompiledGraph

from chat_agent_base import BaseChatState

Context = TypeVar("Context")


class BaseAgent(Generic[Context]):
    """
    Baseclass for all agents managed by the orchestrator.
    """

    @staticmethod
    @abstractmethod
    def run(ctx: Context) -> Context:
        """
        Run the agent on a specific context.
        """

    @staticmethod
    def get_log_file(agent_name: str) -> Path:
        """Get log file."""
        scratch_space = os.environ.get("AIXCC_CRS_SCRATCH_SPACE")
        log_file = (
            Path(scratch_space) / f"{agent_name}_{datetime.datetime.now()}.md"
            if scratch_space
            else Path(f"{agent_name}.md")
        )

        return log_file

    @staticmethod
    def run_and_report_output(
            compiled_graph: CompiledGraph,
            init_state: BaseChatState,
            to_stdout=True,
            to_markdown=True,
            verbose=False,
            md_file_name: Path | None = None,
            config: RunnableConfig | None = None,
    ) -> BaseMessage:
        """
        runs the runnable and reports output to stout / markdown as configured
        Args:
            runnable: the compiled graph to run
            init_state: the state where to start
            to_stdout: print conversation to stout if True
            to_markdown: save conversation to md if True
            md_file_name: overwrite the md-filename (standard is current file name) if to_markdown is enabled
            config: config dict that will be passed to runnable.stream()

        Returns:
            The last AIMessage which should contain the answer to our problem
        """

        if config is None:
            config = RunnableConfig()

        seen_message_count = 0

        for output in compiled_graph.stream(init_state, config, stream_mode="values"):
            messages = output["messages"]
            last_message: BaseMessage = messages[-1]

            if to_stdout:
                for msg in messages[seen_message_count:]:
                    print()
                    print(f"#### {msg.__class__.__name__} ".ljust(80, "#"))

                    msg_dict = msg.dict()
                    del msg_dict["content"]

                    if isinstance(msg, AIMessage):
                        print(f"[Model: {msg.response_metadata['model_name']}]")
                        print()
                    elif isinstance(msg, ToolMessage):
                        print(f"[Tool: {msg.name}]")
                        print()
                        del msg_dict["name"]

                    print(msg.content)

                    if not verbose:
                        del msg_dict["additional_kwargs"]
                        del msg_dict["response_metadata"]
                    print(json.dumps(msg_dict, indent=4))

                seen_message_count = len(messages)

            if to_markdown:
                BaseAgent.graph_output_to_markdown(
                    output, output_file=md_file_name or Path(f"{__name__.rsplit('.', maxsplit=1)[-1]}.md")
                )

        return last_message

    @staticmethod
    def graph_output_to_markdown(output: dict, output_file: Path) -> None:
        """
        Create markdown file with formatted conversation from compiledGraph.stream() output.
        """

        out = ""
        for msg in output["messages"]:
            out += f"#### {msg.__class__.__name__} \n"

            if isinstance(msg, AIMessage):
                out += f"Model: `{msg.response_metadata['model_name']}`\n\n"
                out += f"{msg.content}\n\n"
                if len(msg.tool_calls) > 0:
                    out += "*Tool calls*\n"
                    out += f"```json\n{json.dumps(msg.tool_calls, indent=4)}\n````\n"
            elif isinstance(msg, ToolMessage):
                out += f"Tool name: `{msg.name}`\n\n"
                out += f"Result:\n{msg.content}\n"
            else:
                out += f"{msg.content}\n\n"

            out += "\n---\n\n"

        output_file.write_text(out, encoding="utf-8")
