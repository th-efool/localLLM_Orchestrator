COMPOSE ?= docker compose

.PHONY: up up-vllm down restart logs health verify clean

up:
	$(COMPOSE) up -d

up-vllm:
	@if $(COMPOSE) config --profiles 2>/dev/null | tr ' ' '\n' | grep -qx 'with-vllm'; then \
		$(COMPOSE) --profile with-vllm up -d; \
	else \
		echo "with-vllm profile is not configured in docker-compose.yml; base stack started with 'make up'."; \
		$(COMPOSE) up -d; \
	fi

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
