COMPOSE ?= docker compose

.PHONY: up up-vllm down restart logs logs-vllm health verify verify-vllm gpu-check clean

up:
	$(COMPOSE) up -d

up-vllm:
	VLLM_API_BASE=http://vllm:8000 $(COMPOSE) --profile with-vllm up -d postgres redis vllm
	@for i in $$(seq 1 120); do \
		state=$$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' localai-vllm 2>/dev/null || echo missing); \
		[ "$$state" = healthy ] && break; \
		[ $$i -eq 120 ] && echo "localai-vllm health=$$state" && exit 1; \
		sleep 5; \
	done
	VLLM_API_BASE=http://vllm:8000 $(COMPOSE) --profile with-vllm up -d

down:
	$(COMPOSE) down --remove-orphans

restart:
	$(COMPOSE) down --remove-orphans
	$(COMPOSE) up -d

logs:
	$(COMPOSE) logs -f --tail=200

logs-vllm:
	$(COMPOSE) --profile with-vllm logs -f --tail=200 vllm litellm

health:
	./scripts/healthcheck.sh

verify:
	./scripts/verify.sh

verify-vllm:
	VERIFY_VLLM=true ./scripts/verify.sh

gpu-check:
	docker exec localai-vllm nvidia-smi

clean:
	$(COMPOSE) down --remove-orphans --volumes
