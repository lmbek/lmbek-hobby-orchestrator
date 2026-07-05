# ──────────────────────────────────────────────────────────────
# Orchestrators — Makefile
# Convenience targets for every Docker Compose grouping.
# Default environment: local.  Override with ENV=stage|prod.
# ──────────────────────────────────────────────────────────────

.DEFAULT_GOAL := help

# Environment: local | stage | prod  (default: local)
ENV ?= local

# ── Compose file mapping ────────────────────────────────────
PROXY_FILE            := docker-compose.proxy.local.yml
APPS_FILE             := docker-compose.applications.$(ENV).yml
APPS_GROUP_A_FILE     := docker-compose.applications-groupA.$(ENV).yml
APPS_GROUP_B_FILE     := docker-compose.applications-groupB.$(ENV).yml
DOCS_FILE             := docker-compose.docs.$(ENV).yml

# Local builds need --build; stage/prod pull pre-built images.
ifeq ($(ENV),local)
  BUILD_FLAG := --build
else
  BUILD_FLAG :=
endif

# ── Colours (ANSI) ──────────────────────────────────────────
CYAN  := \033[36m
GREEN := \033[32m
BOLD  := \033[1m
RESET := \033[0m

# ════════════════════════════════════════════════════════════
#  All — bring up / tear down the full local stack
# ════════════════════════════════════════════════════════════

.PHONY: all
all: proxy-up apps-up docs-up ## Start everything (proxy → apps → docs)

.PHONY: all-down
all-down: docs-down apps-down proxy-down ## Stop everything (docs → apps → proxy)

.PHONY: all-restart
all-restart: all-down all ## Restart the full stack

.PHONY: all-ps
all-ps: proxy-ps apps-ps docs-ps ## Show containers for all groupings

.PHONY: all-logs
all-logs: ## Tail logs for all groupings (Ctrl-C to stop)
	@docker compose -f $(PROXY_FILE) -f $(APPS_FILE) -f $(DOCS_FILE) logs -f --tail=50

# ════════════════════════════════════════════════════════════
#  Proxy
# ════════════════════════════════════════════════════════════

.PHONY: proxy-up
proxy-up: ## Start the Traefik reverse proxy (creates the shared network)
	@printf "$(CYAN)▶ Starting proxy …$(RESET)\n"
	docker compose -f $(PROXY_FILE) up -d

.PHONY: proxy-down
proxy-down: ## Stop the proxy
	docker compose -f $(PROXY_FILE) down

.PHONY: proxy-restart
proxy-restart: proxy-down proxy-up ## Restart the proxy

.PHONY: proxy-ps
proxy-ps: ## Show proxy containers
	docker compose -f $(PROXY_FILE) ps

.PHONY: proxy-logs
proxy-logs: ## Tail proxy logs
	docker compose -f $(PROXY_FILE) logs -f --tail=50

# ════════════════════════════════════════════════════════════
#  Applications — all services
# ════════════════════════════════════════════════════════════

.PHONY: apps-up
apps-up: ## Start all application services
	@printf "$(CYAN)▶ Starting all applications ($(ENV)) …$(RESET)\n"
	docker compose -f $(APPS_FILE) up -d $(BUILD_FLAG)

.PHONY: apps-down
apps-down: ## Stop all application services
	docker compose -f $(APPS_FILE) down

.PHONY: apps-restart
apps-restart: apps-down apps-up ## Restart all application services

.PHONY: apps-ps
apps-ps: ## Show application containers
	docker compose -f $(APPS_FILE) ps

.PHONY: apps-logs
apps-logs: ## Tail application logs
	docker compose -f $(APPS_FILE) logs -f --tail=50

.PHONY: apps-build
apps-build: ## Build all application images (local only)
	docker compose -f $(APPS_FILE) build

# ════════════════════════════════════════════════════════════
#  Applications — Group A
# ════════════════════════════════════════════════════════════

.PHONY: group-a-up
group-a-up: ## Start Group A services
	@printf "$(CYAN)▶ Starting Group A ($(ENV)) …$(RESET)\n"
	docker compose -f $(APPS_GROUP_A_FILE) up -d $(BUILD_FLAG)

.PHONY: group-a-down
group-a-down: ## Stop Group A services
	docker compose -f $(APPS_GROUP_A_FILE) down

.PHONY: group-a-restart
group-a-restart: group-a-down group-a-up ## Restart Group A services

.PHONY: group-a-ps
group-a-ps: ## Show Group A containers
	docker compose -f $(APPS_GROUP_A_FILE) ps

.PHONY: group-a-logs
group-a-logs: ## Tail Group A logs
	docker compose -f $(APPS_GROUP_A_FILE) logs -f --tail=50

.PHONY: group-a-build
group-a-build: ## Build Group A images (local only)
	docker compose -f $(APPS_GROUP_A_FILE) build

# ════════════════════════════════════════════════════════════
#  Applications — Group B
# ════════════════════════════════════════════════════════════

.PHONY: group-b-up
group-b-up: ## Start Group B services
	@printf "$(CYAN)▶ Starting Group B ($(ENV)) …$(RESET)\n"
	docker compose -f $(APPS_GROUP_B_FILE) up -d $(BUILD_FLAG)

.PHONY: group-b-down
group-b-down: ## Stop Group B services
	docker compose -f $(APPS_GROUP_B_FILE) down

.PHONY: group-b-restart
group-b-restart: group-b-down group-b-up ## Restart Group B services

.PHONY: group-b-ps
group-b-ps: ## Show Group B containers
	docker compose -f $(APPS_GROUP_B_FILE) ps

.PHONY: group-b-logs
group-b-logs: ## Tail Group B logs
	docker compose -f $(APPS_GROUP_B_FILE) logs -f --tail=50

.PHONY: group-b-build
group-b-build: ## Build Group B images (local only)
	docker compose -f $(APPS_GROUP_B_FILE) build

# ════════════════════════════════════════════════════════════
#  Documentation
# ════════════════════════════════════════════════════════════

.PHONY: docs-up
docs-up: ## Start the documentation site
	@printf "$(CYAN)▶ Starting docs ($(ENV)) …$(RESET)\n"
	docker compose -f $(DOCS_FILE) up -d $(BUILD_FLAG)

.PHONY: docs-down
docs-down: ## Stop the documentation site
	docker compose -f $(DOCS_FILE) down

.PHONY: docs-restart
docs-restart: docs-down docs-up ## Restart the documentation site

.PHONY: docs-ps
docs-ps: ## Show docs containers
	docker compose -f $(DOCS_FILE) ps

.PHONY: docs-logs
docs-logs: ## Tail docs logs
	docker compose -f $(DOCS_FILE) logs -f --tail=50

.PHONY: docs-build
docs-build: ## Build docs image (local only)
	docker compose -f $(DOCS_FILE) build

# ════════════════════════════════════════════════════════════
#  Utilities
# ════════════════════════════════════════════════════════════

.PHONY: status
status: ## Show running containers across all compose files
	@printf "$(BOLD)$(GREEN)── Proxy ──$(RESET)\n"
	@docker compose -f $(PROXY_FILE) ps 2>/dev/null || true
	@printf "$(BOLD)$(GREEN)── Applications ──$(RESET)\n"
	@docker compose -f $(APPS_FILE) ps 2>/dev/null || true
	@printf "$(BOLD)$(GREEN)── Docs ──$(RESET)\n"
	@docker compose -f $(DOCS_FILE) ps 2>/dev/null || true

.PHONY: pull
pull: ## Pull latest images for stage/prod
	docker compose -f $(APPS_FILE) pull
	docker compose -f $(DOCS_FILE) pull

.PHONY: clean
clean: all-down ## Stop everything and remove orphan containers, volumes, and images
	docker compose -f $(PROXY_FILE) down --volumes --remove-orphans --rmi local 2>/dev/null || true
	docker compose -f $(APPS_FILE) down --volumes --remove-orphans --rmi local 2>/dev/null || true
	docker compose -f $(DOCS_FILE) down --volumes --remove-orphans --rmi local 2>/dev/null || true
	@printf "$(GREEN)✔ Cleaned up all containers, volumes, and local images.$(RESET)\n"

.PHONY: validate
validate: ## Validate all compose files (docker compose config)
	@printf "$(CYAN)Validating compose files …$(RESET)\n"
	@docker compose -f $(PROXY_FILE) config -q && printf "  ✔ $(PROXY_FILE)\n"
	@docker compose -f $(APPS_FILE) config -q && printf "  ✔ $(APPS_FILE)\n"
	@docker compose -f $(APPS_GROUP_A_FILE) config -q && printf "  ✔ $(APPS_GROUP_A_FILE)\n"
	@docker compose -f $(APPS_GROUP_B_FILE) config -q && printf "  ✔ $(APPS_GROUP_B_FILE)\n"
	@docker compose -f $(DOCS_FILE) config -q && printf "  ✔ $(DOCS_FILE)\n"
	@printf "$(GREEN)All compose files valid.$(RESET)\n"

.PHONY: network
network: ## Create the shared hobby-net network (idempotent)
	@docker network create orchestrators_hobby-net 2>/dev/null || printf "Network already exists.\n"

# ════════════════════════════════════════════════════════════
#  Help
# ════════════════════════════════════════════════════════════

.PHONY: help
help: ## Show this help
	@printf "$(BOLD)Orchestrators — available targets$(RESET)  (ENV=$(ENV))\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'
	@printf "\nOverride environment:  $(BOLD)make apps-up ENV=stage$(RESET)\n"
