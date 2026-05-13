COMPOSE ?= docker compose

.PHONY: start start-vllm start-ollama stop restart logs ps healthcheck validate

start:
	./scripts/bootstrap.sh

start-vllm:
	./scripts/bootstrap.sh --profile with-vllm

start-ollama:
	./scripts/bootstrap.sh --profile with-ollama

stop:
	$(COMPOSE) down

restart:
	$(COMPOSE) down
	./scripts/bootstrap.sh

logs:
	$(COMPOSE) logs -f --tail=200

ps:
	$(COMPOSE) ps

healthcheck:
	./scripts/healthcheck.sh

validate:
	$(COMPOSE) config
