import os
from typing import TypedDict
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI

BASE_URL = os.getenv("OPENAI_BASE_URL", "http://localhost:4000/v1")
API_KEY = os.getenv("OPENAI_API_KEY", "sk-local-change-me")

fast = ChatOpenAI(model="phi4", base_url=BASE_URL, api_key=API_KEY, temperature=0)
reasoning = ChatOpenAI(model="qwen3.5:35b", base_url=BASE_URL, api_key=API_KEY, temperature=0)

class State(TypedDict):
    query: str
    route: str
    answer: str

def router(state: State):
    q = state["query"].lower()
    route = "reasoning" if any(k in q for k in ["design", "architecture", "debug", "plan"]) else "fast"
    return {"route": route}

def worker(state: State):
    llm = reasoning if state["route"] == "reasoning" else fast
    msg = llm.invoke(state["query"])
    return {"answer": msg.content}

workflow = StateGraph(State)
workflow.add_node("router", router)
workflow.add_node("worker", worker)
workflow.set_entry_point("router")
workflow.add_edge("router", "worker")
workflow.add_edge("worker", END)
app = workflow.compile()

if __name__ == "__main__":
    print(app.invoke({"query": "Design a refactor plan", "route": "", "answer": ""}))
