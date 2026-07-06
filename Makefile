# ──────────────────────────────────────────────────────────────
# Orchestrators — Makefile
# Convenience targets for Docker Compose services.
# Local development only.  Stage/prod lives in infrastructure/platform.
# ──────────────────────────────────────────────────────────────

.DEFAULT_GOAL := help

# ── Compose file mapping ────────────────────────────────────
PROXY_FILE      := docker-compose.proxy.yml
APPS_FILE       := docker-compose.applications.yml
DOCS_FILE       := docker-compose.docs.yml
MONITORING_FILE := ../observability/docker-compose.yml

# ── Colours (ANSI) ──────────────────────────────────────────
CYAN  := \033[36m
GREEN := \033[32m
BOLD  := \033[1m
RESET := \033[0m

# Always build from source for local development.
BUILD_FLAG := --build

# ════════════════════════════════════════════════════════════
#  All — bring up / tear down the full local stack
# ════════════════════════════════════════════════════════════

.PHONY: up
up: proxy-up apps-up docs-up monitoring-up ## Start everything (proxy → apps → docs → monitoring)

.PHONY: down
down: monitoring-down docs-down apps-down proxy-down ## Stop everything (monitoring → docs → apps → proxy)

.PHONY: restart
restart: down up ## Restart the full stack

.PHONY: ps
ps: ## Show running containers across all compose files
	@printf "$(BOLD)$(GREEN)── Proxy ──$(RESET)\n"
	@docker compose -f $(PROXY_FILE) ps 2>/dev/null || true
	@printf "$(BOLD)$(GREEN)── Applications ──$(RESET)\n"
	@docker compose -f $(APPS_FILE) ps 2>/dev/null || true
	@printf "$(BOLD)$(GREEN)── Docs ──$(RESET)\n"
	@docker compose -f $(DOCS_FILE) ps 2>/dev/null || true
	@printf "$(BOLD)$(GREEN)── Monitoring ──$(RESET)\n"
	@docker compose -f $(MONITORING_FILE) ps 2>/dev/null || true

.PHONY: logs
logs: ## Tail logs for all services (Ctrl-C to stop)
	@docker compose -f $(PROXY_FILE) -f $(APPS_FILE) -f $(DOCS_FILE) logs -f --tail=50

# ════════════════════════════════════════════════════════════
#  Proxy
# ════════════════════════════════════════════════════════════

.PHONY: proxy-up
proxy-up: network ## Start the reverse proxy
	@printf "$(CYAN)▶ Starting proxy …$(RESET)\n"
	docker compose -f $(PROXY_FILE) up -d --remove-orphans

.PHONY: proxy-down
proxy-down: ## Stop the reverse proxy
	docker compose -f $(PROXY_FILE) down

.PHONY: proxy-restart
proxy-restart: proxy-down proxy-up ## Restart the reverse proxy

.PHONY: proxy-logs
proxy-logs: ## Tail proxy logs
	docker compose -f $(PROXY_FILE) logs -f --tail=50

# ════════════════════════════════════════════════════════════
#  Applications
# ════════════════════════════════════════════════════════════

.PHONY: apps-up
apps-up: ## Start all application services
	@printf "$(CYAN)▶ Starting applications …$(RESET)\n"
	docker compose -f $(APPS_FILE) up -d --remove-orphans $(BUILD_FLAG)

.PHONY: apps-down
apps-down: ## Stop all application services
	docker compose -f $(APPS_FILE) down

.PHONY: apps-restart
apps-restart: apps-down apps-up ## Restart all application services

.PHONY: apps-logs
apps-logs: ## Tail application logs
	docker compose -f $(APPS_FILE) logs -f --tail=50

.PHONY: apps-build
apps-build: ## Build all application images
	docker compose -f $(APPS_FILE) build

# ════════════════════════════════════════════════════════════
#  Single service  (e.g. make service-up S=placeholder1-service)
# ════════════════════════════════════════════════════════════

.PHONY: service-up
service-up: ## Start one service          (S=<name>)
	@test -n "$(S)" || (printf "Usage: make service-up S=<service-name>\n" && exit 1)
	@printf "$(CYAN)▶ Starting $(S) …$(RESET)\n"
	docker compose -f $(APPS_FILE) up -d --remove-orphans $(BUILD_FLAG) $(S)

.PHONY: service-down
service-down: ## Stop one service           (S=<name>)
	@test -n "$(S)" || (printf "Usage: make service-down S=<service-name>\n" && exit 1)
	docker compose -f $(APPS_FILE) stop $(S)

.PHONY: service-restart
service-restart: service-down service-up ## Restart one service        (S=<name>)

.PHONY: service-logs
service-logs: ## Tail logs for one service  (S=<name>)
	@test -n "$(S)" || (printf "Usage: make service-logs S=<service-name>\n" && exit 1)
	docker compose -f $(APPS_FILE) logs -f --tail=50 $(S)

.PHONY: service-build
service-build: ## Build one service image    (S=<name>)
	@test -n "$(S)" || (printf "Usage: make service-build S=<service-name>\n" && exit 1)
	docker compose -f $(APPS_FILE) build $(S)

# ════════════════════════════════════════════════════════════
#  Docs
# ════════════════════════════════════════════════════════════

.PHONY: docs-up
docs-up: ## Start the documentation site
	@printf "$(CYAN)▶ Starting docs …$(RESET)\n"
	docker compose -f $(DOCS_FILE) up -d --remove-orphans $(BUILD_FLAG)

.PHONY: docs-down
docs-down: ## Stop the documentation site
	docker compose -f $(DOCS_FILE) down

.PHONY: docs-restart
docs-restart: docs-down docs-up ## Restart the documentation site

.PHONY: docs-logs
docs-logs: ## Tail docs logs
	docker compose -f $(DOCS_FILE) logs -f --tail=50

.PHONY: docs-build
docs-build: ## Build docs image
	docker compose -f $(DOCS_FILE) build

# ════════════════════════════════════════════════════════════
#  Monitoring
# ════════════════════════════════════════════════════════════

.PHONY: monitoring-up
monitoring-up: network ## Start the monitoring stack
	@printf "$(CYAN)▶ Starting monitoring …$(RESET)\n"
	docker compose -f $(MONITORING_FILE) up -d --remove-orphans

.PHONY: monitoring-down
monitoring-down: ## Stop the monitoring stack
	docker compose -f $(MONITORING_FILE) down

.PHONY: monitoring-restart
monitoring-restart: monitoring-down monitoring-up ## Restart the monitoring stack

.PHONY: monitoring-logs
monitoring-logs: ## Tail monitoring logs
	docker compose -f $(MONITORING_FILE) logs -f --tail=50

# ════════════════════════════════════════════════════════════
#  Utilities
# ════════════════════════════════════════════════════════════

.PHONY: pull
pull: ## Pull latest images for all services
	docker compose -f $(PROXY_FILE) pull
	docker compose -f $(APPS_FILE) pull
	docker compose -f $(DOCS_FILE) pull

.PHONY: clean
clean: down ## Stop everything and remove volumes, orphans, and local images
	docker compose -f $(PROXY_FILE) down --volumes --remove-orphans --rmi local 2>/dev/null || true
	docker compose -f $(APPS_FILE) down --volumes --remove-orphans --rmi local 2>/dev/null || true
	docker compose -f $(DOCS_FILE) down --volumes --remove-orphans --rmi local 2>/dev/null || true
	docker compose -f $(MONITORING_FILE) down --volumes --remove-orphans --rmi local 2>/dev/null || true
	@printf "$(GREEN)✔ Cleaned up.$(RESET)\n"

.PHONY: validate
validate: ## Validate all compose files
	@printf "$(CYAN)Validating compose files …$(RESET)\n"
	@docker compose -f $(PROXY_FILE) config -q && printf "  ✔ $(PROXY_FILE)\n"
	@docker compose -f $(APPS_FILE) config -q && printf "  ✔ $(APPS_FILE)\n"
	@docker compose -f $(DOCS_FILE) config -q && printf "  ✔ $(DOCS_FILE)\n"
	@printf "$(GREEN)All compose files valid.$(RESET)\n"

.PHONY: network
network: ## Create the shared networks (idempotent)
	@docker network create hobby-internal 2>/dev/null || printf "hobby-internal already exists.\n"
	@docker network create hobby-external 2>/dev/null || printf "hobby-external already exists.\n"

# ════════════════════════════════════════════════════════════
#  Help
# ════════════════════════════════════════════════════════════

.PHONY: help
help: ## Show this help
	@printf "$(BOLD)Orchestrators — available targets$(RESET)\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'
	@printf "\nSingle-service example: make service-up S=placeholder1-service\n"
	@printf "Stage/prod deployments live in infrastructure/platform (ArgoCD + Kubernetes).\n"
