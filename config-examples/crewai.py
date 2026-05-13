import os
from crewai import Agent, Task, Crew
from langchain_openai import ChatOpenAI

BASE_URL = os.getenv("OPENAI_BASE_URL", "http://localhost:4000/v1")
API_KEY = os.getenv("OPENAI_API_KEY", "sk-local-change-me")

fast_llm = ChatOpenAI(model="phi4", base_url=BASE_URL, api_key=API_KEY, temperature=0)
reasoning_llm = ChatOpenAI(model="qwen3.5:35b", base_url=BASE_URL, api_key=API_KEY, temperature=0)

planner = Agent(role="Planner", goal="Plan architecture", backstory="Senior architect", llm=reasoning_llm)
executor = Agent(role="Executor", goal="Implement tasks", backstory="Senior engineer", llm=fast_llm)

task = Task(description="Create implementation checklist for a feature.", agent=planner)
crew = Crew(agents=[planner, executor], tasks=[task])

if __name__ == "__main__":
    print(crew.kickoff())
