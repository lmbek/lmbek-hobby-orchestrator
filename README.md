# Orchestrators

Per-grouping Docker Compose files that wire all services together. Each grouping has **local**, **stage**, and **prod** variants.

## Quick Start (Local)

The easiest way is with `make`:

```bash
make all          # Start everything (proxy → apps → docs)
make all-down     # Stop everything
make status       # Show what's running
make help         # List all available targets
```

Or start individual groupings:

```bash
make proxy-up     # Traefik reverse proxy (creates the shared network)
make apps-up      # All application services
make group-a-up   # Group A only (Team A)
make group-b-up   # Group B only (Team B)
make docs-up      # Documentation site
```

Override the environment for staging or production:

```bash
make apps-up ENV=stage
make apps-up ENV=prod
```

<details>
<summary>Without Make (raw docker compose commands)</summary>

```bash
docker compose -f docker-compose.proxy.local.yml up -d
docker compose -f docker-compose.applications.local.yml up -d --build
docker compose -f docker-compose.applications-groupA.local.yml up -d --build
docker compose -f docker-compose.applications-groupB.local.yml up -d --build
docker compose -f docker-compose.docs.local.yml up -d --build
```

Stop everything:

```bash
docker compose -f docker-compose.proxy.local.yml down
docker compose -f docker-compose.applications.local.yml down
docker compose -f docker-compose.docs.local.yml down
```

</details>

## Makefile Targets

Run `make help` to see all targets. Key ones:

| Target | Description |
|--------|-------------|
| `make all` | Start the full stack (proxy → apps → docs) |
| `make all-down` | Stop everything (reverse order) |
| `make all-restart` | Restart the full stack |
| `make proxy-up/down/restart` | Manage the Traefik proxy |
| `make apps-up/down/restart` | Manage all application services |
| `make group-a-up/down/restart` | Manage Group A services |
| `make group-b-up/down/restart` | Manage Group B services |
| `make docs-up/down/restart` | Manage the documentation site |
| `make status` | Show running containers across all groupings |
| `make *-logs` | Tail logs for any grouping |
| `make *-ps` | Show containers for any grouping |
| `make *-build` | Build images (local only) |
| `make validate` | Validate all compose files |
| `make clean` | Stop everything and remove volumes/images |
| `make pull` | Pull latest images (stage/prod) |
| `make network` | Create the shared network (idempotent) |

All targets default to `ENV=local`. Override with `ENV=stage` or `ENV=prod`.

## Compose Files

| File | Grouping | Environment | Description |
|------|----------|-------------|-------------|
| `docker-compose.proxy.local.yml` | Proxy | Local | Traefik reverse proxy + homepage (local only) |
| `docker-compose.applications.local.yml` | Applications (all) | Local | Builds all services from source |
| `docker-compose.applications.stage.yml` | Applications (all) | Staging | Pre-built images from registry |
| `docker-compose.applications.prod.yml` | Applications (all) | Production | Pre-built images, `restart: always` |
| `docker-compose.applications-groupA.local.yml` | Applications (Group A) | Local | Builds Group A services from source |
| `docker-compose.applications-groupA.stage.yml` | Applications (Group A) | Staging | Pre-built images from registry |
| `docker-compose.applications-groupA.prod.yml` | Applications (Group A) | Production | Pre-built images, `restart: always` |
| `docker-compose.applications-groupB.local.yml` | Applications (Group B) | Local | Builds Group B services from source |
| `docker-compose.applications-groupB.stage.yml` | Applications (Group B) | Staging | Pre-built images from registry |
| `docker-compose.applications-groupB.prod.yml` | Applications (Group B) | Production | Pre-built images, `restart: always` |
| `docker-compose.docs.local.yml` | Docs | Local | Builds docs from source |
| `docker-compose.docs.stage.yml` | Docs | Staging | Pre-built image from registry |
| `docker-compose.docs.prod.yml` | Docs | Production | Pre-built image, `restart: always` |

## Structure

```
orchestrators/
├── docker-compose.proxy.local.yml                # Traefik proxy (local only)
├── docker-compose.applications.local.yml         # All app services — local
├── docker-compose.applications.stage.yml         # All app services — staging
├── docker-compose.applications.prod.yml          # All app services — production
├── docker-compose.applications-groupA.local.yml  # Group A — local
├── docker-compose.applications-groupA.stage.yml  # Group A — staging
├── docker-compose.applications-groupA.prod.yml   # Group A — production
├── docker-compose.applications-groupB.local.yml  # Group B — local
├── docker-compose.applications-groupB.stage.yml  # Group B — staging
├── docker-compose.applications-groupB.prod.yml   # Group B — production
├── docker-compose.docs.local.yml                 # Documentation — local
├── docker-compose.docs.stage.yml                 # Documentation — staging
├── docker-compose.docs.prod.yml                  # Documentation — production
├── proxy/
│   ├── traefik.yml                         # Traefik static configuration
│   ├── dynamic.yml                         # Traefik dynamic routing rules
│   └── homepage/
│       └── index.html                      # Proxy landing page (served at /)
└── README.md
```

## Architecture

- The **proxy** compose creates the `orchestrators_hobby-net` bridge network. All other composes join it as an external network.
- The proxy is **local environment only** — staging and production do not use it.
- **Observability** lives in the separate `observability` repo and connects directly to services, bypassing the proxy.
- **Group composes** (groupA, groupB) let individual teams run only the services they own, without spinning up the entire stack.
- The "all applications" compose files still exist for running everything together.
- Stage and prod composes pull pre-built images from the container registry instead of building from source.
