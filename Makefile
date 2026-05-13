COMPOSE ?= docker compose

.PHONY: start start-vllm start-ollama start-openhands stop stop-openhands restart logs logs-openhands ps healthcheck validate api-verify smoke-test route-verify verify-openhands logs-litellm logs-webui gpu-check

start:
	./scripts/bootstrap.sh

start-vllm:
	./scripts/bootstrap.sh --profile with-vllm

start-ollama:
	./scripts/bootstrap.sh --profile with-ollama

start-openhands:
	./scripts/bootstrap.sh --profile with-openhands

stop:
	$(COMPOSE) down

stop-openhands:
	$(COMPOSE) --profile with-openhands stop openhands

restart:
	$(COMPOSE) down
	./scripts/bootstrap.sh

logs:
	$(COMPOSE) logs -f --tail=200

logs-openhands:
	$(COMPOSE) --profile with-openhands logs -f --tail=200 openhands

ps:
	$(COMPOSE) ps

healthcheck:
	./scripts/healthcheck.sh

validate:
	$(COMPOSE) config

api-verify:
	./scripts/api_verify.sh

smoke-test:
	./scripts/smoke_test.sh

route-verify:
	./scripts/route_verify.sh

verify-openhands:
	./scripts/openhands_verify.sh

logs-litellm:
	$(COMPOSE) logs -f --tail=200 litellm

logs-webui:
	$(COMPOSE) logs -f --tail=200 open-webui

gpu-check:
	docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi
