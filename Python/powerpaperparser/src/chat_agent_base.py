"""Base class definition for basic chat agents with tool calling ability."""

import datetime
import os
import random
import time
from pathlib import Path
from typing import Callable

import openai
from langchain_core.language_models import LanguageModelInput
from langchain_core.messages import AIMessage
from langchain_core.messages import BaseMessage
from langchain_core.messages import ToolCall
from langchain_core.messages import ToolMessage
from langchain_core.runnables import Runnable
from langchain_core.tools import BaseTool
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import ToolExecutor
from langgraph.prebuilt import ToolInvocation
from pydantic.v1 import BaseModel
from pydantic.v1 import Field

from logger import crs_logger

log = crs_logger.getChild(__name__)


class BaseChatState(BaseModel):
    """
    Base state used by other classes in this file. If your agent uses classes from this file
    your state should be derived from this class.
    """

    messages: list[BaseMessage]
    processed_tools: set[str] = Field(default_factory=set)  # str is tool call id

    @property
    def last_ai_message(self) -> AIMessage:
        """Get the last message received from AI (None if no AIMessage exists)"""
        for msg in reversed(self.messages):
            if isinstance(msg, AIMessage):
                return msg

        raise ValueError("No AIMessage in self.messages")

    @property
    def next_unprocessed_tool_call(self) -> ToolCall | None:
        """Get next tool_call from latest AIMessage that is not handled (None if no Call is left)"""
        message = self.last_ai_message

        if not message.tool_calls:
            return None

        for tool_call in message.tool_calls:
            if self.get_unique_tool_id(tool_call, message) not in self.processed_tools:
                return tool_call

        return None

    def get_unique_tool_id(self, tool_call: ToolCall, message: AIMessage | None = None):
        """Construct a unique ID for a particular tool call."""
        if message is None:
            message = self.last_ai_message

        return f"{tool_call['id']}_{message.id}"


# The following classes are also defined in langgraph but only work on TypedDicts states


class SingleToolExecutorNode:
    """Used to execute the next unexecuted tool in the last AIMessage."""

    def __init__(self, tools: list[BaseTool | Callable]):
        self.tool_executor = ToolExecutor(tools)

    def _run_tool(self, tool_call):
        tool_name = tool_call["name"]

        # when a tool is not registered but somewhere mentioned in a prompt the LLM might hallucinate a name
        # this is not caught by langgraph and results in a 400: bad request
        # an assistant message with \'tool_calls\' must be followed by tool messages responding to each \'tool_call_id\'
        # we raise a descriptive error as warning that it's probably a user warning so we detect it
        if tool_name not in self.tool_executor.tool_map:
            raise ValueError(
                f"Tried to call tool '{tool_name}' which does not exist.\n"
                f"This is most likely because the existence of a tool was mentioned in a prompt but not registered.\n"
                f"Please ensure that all tools are registered correctly. "
                f"If this error continues consider catching it and telling the LLM that such a tool doesn't exist"
            )

        invocation = ToolInvocation(
            tool=tool_name,
            tool_input=tool_call["args"],
        )

        result = self.tool_executor.invoke(invocation)
        tool_message = ToolMessage(
            content=str(result),
            name=invocation.tool,
            tool_call_id=tool_call["id"],
        )
        return tool_message

    def __call__(self, state: BaseChatState) -> BaseChatState:
        """Calls next tool on last AIMessage"""

        tool_call = state.next_unprocessed_tool_call
        if tool_call is None:
            raise ValueError("There is no tool to call")

        tool_message = self._run_tool(tool_call)
        state.processed_tools.add(state.get_unique_tool_id(tool_call, state.last_ai_message))  # pylint: disable=E1101

        state.messages.append(tool_message)
        return state


class ToolExecutorNode(SingleToolExecutorNode):
    """
    Node which should be called after a model wants to execute a tool.
    """

    def __call__(self, state: BaseChatState) -> BaseChatState:
        """Call tool(s). Executes all tools that are uncalled in the last AIMessage"""

        last_ai_message = state.last_ai_message

        tool_messages = [
            self._run_tool(tool_call)
            for tool_call in last_ai_message.tool_calls
            # ensure that we don't call a tool again that has been called by a previous (singular) call
            if state.get_unique_tool_id(tool_call, last_ai_message) not in state.processed_tools
        ]

        state.processed_tools.update(
            state.get_unique_tool_id(tool_call, last_ai_message) for tool_call in last_ai_message.tool_calls
        )  # type: ignore
        state.messages.extend(tool_messages)
        return state


def get_model_with_tools(
        model: str,
        tools: list[BaseTool | Callable],
        temperature: float = 0.7,
) -> Runnable[LanguageModelInput, BaseMessage]:
    """Get llm model with tools bound to it."""

    model = ChatOpenAI(
        model=model,
        temperature=temperature,  # type: ignore
    ).bind_tools(tools)

    return model  # type: ignore


MODEL_LIST = [
    # "gemini-1.5-pro",
    "oai-gpt-4o",
    # "azure-gpt-4o",
    # "claude-3-opus",
    # "claude-3-haiku",
    "oai-gpt-4",
    "oai-gpt-4-turbo",
    # "claude-3-sonnet"
]


class CallModelNode:
    """
    Node which calls the llm on the current state.
    """

    def __init__(
            self,
            model_name: str,
            tools: list[BaseTool | Callable],
            temperature: float = 0.7,
    ) -> None:

        self.model_name = model_name
        self.tools = tools
        self.temperature = temperature
        self.model = get_model_with_tools(model_name, tools, temperature)

        scratch_space = os.environ.get("AIXCC_CRS_SCRATCH_SPACE")
        log_file = (
            Path(scratch_space) / f"messages_{datetime.datetime.now()}.log" if scratch_space else Path("messages.log")
        )

        self.message_log = log_file

    def __call__(self, state: BaseChatState) -> BaseChatState:
        """Call model."""

        # use random model for next llm call
        if self.model_name == "":
            self.model = get_model_with_tools(random.choice(MODEL_LIST), self.tools, self.temperature)

        self.message_log.write_text(state.json(indent=2), encoding="utf-8")

        # increased limit from 10k to 20k as paper would not finish
        for _ in range(0, 20_000):
            try:
                response = self.model.invoke(state.messages)
                state.messages.append(response)
                break
            except openai.RateLimitError as e:
                if e.code == 429:
                    # ignore "No deployments available for selected model"
                    log.warning('Ignoring LiteLLM API error "No deployments available for selected model"')
                    print(f"RATE LIMIT ERROR IGNORED: {e!r}")
                    time.sleep(10)  # backoff time
                else:
                    raise
            except openai.AuthenticationError as e:
                if e.code == 401:
                    timeout = 60 * 60 * 5

                    log.error("Max API budget exceeded")
                    log.info(f"Going to sleep for {timeout} seconds")

                    print(f"MAX BUDGET EXCEED: {e!r}.\n\nGOING TO SLEEP FOR {timeout} SECONDS")
                    # we do this to keep the logs clean, because container will restart
                    # forever and logs will be polluted with this error
                    time.sleep(timeout)
                else:
                    raise
        else:
            raise RuntimeError("Could not call model! Too many rate limit errors!")

        return state
