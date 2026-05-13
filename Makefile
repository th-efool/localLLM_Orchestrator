COMPOSE ?= docker compose

.PHONY: up down logs restart clean reset-db health shell-litellm

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down --remove-orphans

logs:
	$(COMPOSE) logs -f --tail=200

restart:
	$(COMPOSE) restart

clean:
	$(COMPOSE) down --remove-orphans --volumes

reset-db:
	$(COMPOSE) stop litellm litellm-migrate postgres
	$(COMPOSE) rm -f litellm litellm-migrate postgres
	docker volume rm -f postgres_data litellm_logs
	$(COMPOSE) up -d postgres redis litellm-migrate litellm

health:
	./scripts/healthcheck.sh

shell-litellm:
	$(COMPOSE) exec litellm /bin/bash
