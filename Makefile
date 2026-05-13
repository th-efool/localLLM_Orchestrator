COMPOSE ?= docker compose

.PHONY: up up-vllm down restart logs health verify clean

up:
	$(COMPOSE) up -d

up-vllm:
	$(COMPOSE) --profile with-vllm up -d

down:
	$(COMPOSE) down --remove-orphans

restart:
	$(COMPOSE) down --remove-orphans
	$(COMPOSE) up -d

logs:
	$(COMPOSE) logs -f --tail=200

health:
	./scripts/healthcheck.sh

verify:
	./scripts/verify.sh

clean:
	$(COMPOSE) down --remove-orphans --volumes
