ENV_FILE ?= .env
COMPOSE ?= docker compose --env-file $(ENV_FILE)

.PHONY: up up-vllm down restart logs health verify verify-env diagnose clean logs-vllm verify-vllm gpu-check

.env:
	cp .env.example .env
	@echo "created env file: .env"

verify-env: .env
	ENV_FILE=$(ENV_FILE) COMPOSE='$(COMPOSE)' ./scripts/verify-env.sh

up: .env
	ENV_FILE=$(ENV_FILE) COMPOSE='$(COMPOSE)' ./scripts/verify-env.sh
	$(COMPOSE) up -d

up-vllm: .env
	ENV_FILE=$(ENV_FILE) COMPOSE='$(COMPOSE)' ./scripts/verify-env.sh
	VLLM_API_BASE=http://vllm:8000 COMPOSE_PROFILES=with-vllm $(COMPOSE) up -d postgres redis vllm
	@for i in $$(seq 1 120); do \
		state=$$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' localai-vllm 2>/dev/null || echo missing); \
		[ "$$state" = healthy ] && break; \
		[ $$i -eq 120 ] && echo "localai-vllm health=$$state" && exit 1; \
		sleep 5; \
	done
	VLLM_API_BASE=http://vllm:8000 COMPOSE_PROFILES=with-vllm $(COMPOSE) up -d


down: .env
	$(COMPOSE) down --remove-orphans

restart: down up

logs: .env
	$(COMPOSE) logs -f --tail=200

logs-vllm: .env
	COMPOSE_PROFILES=with-vllm $(COMPOSE) logs -f --tail=200 vllm litellm

health:
	ENV_FILE=$(ENV_FILE) COMPOSE='$(COMPOSE)' ./scripts/healthcheck.sh

verify: verify-env
	ENV_FILE=$(ENV_FILE) COMPOSE='$(COMPOSE)' ./scripts/verify.sh

verify-vllm: verify-env
	VERIFY_VLLM=true ENV_FILE=$(ENV_FILE) COMPOSE='$(COMPOSE)' ./scripts/verify.sh

diagnose: .env
	ENV_FILE=$(ENV_FILE) COMPOSE='$(COMPOSE)' ./scripts/diagnose.sh

gpu-check:
	docker exec localai-vllm nvidia-smi

clean: .env
	$(COMPOSE) down --remove-orphans --volumes
