# SYSTEM_IDENTITY

## Mission
Build a **local-first AI infrastructure platform** that gives developers a stable, OpenAI-compatible interface for inference, orchestration, and agentic software workflows on workstation-class hardware.

## Platform Identity
This repository is the control plane and runtime contract for a workstation-scale AI platform, not a one-off Compose bundle.

It is intended to evolve into:
- unified inference + routing gateway
- agent orchestration foundation
- multi-user secure AI access point
- migration-ready substrate for k3s and later distributed GPU execution

## Long-Term Evolution Goals
- Keep `OpenAI-compatible /v1` endpoints as the primary external contract.
- Keep LiteLLM as the model-routing abstraction boundary.
- Support hybrid local inference (Ollama + vLLM) behind one API.
- Expand from single-user local runtime to multi-user secure gateway.
- Add orchestration capabilities (OpenHands, CrewAI, LangGraph, coding agents) without breaking inference contracts.

## Operational Philosophy
- Local-first by default.
- GPU-centric resource planning.
- Iterative evolution over big-bang rewrites.
- Operational simplicity before platform sophistication.
- Explainable components and maintainable interfaces.
- Defer Kubernetes/distributed complexity until clear load and team requirements justify it.
