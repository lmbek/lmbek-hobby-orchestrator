# Orchestrators

Docker Compose files that wire all services together for local development.
Stage/prod deployments live in `infrastructure/platform` (ArgoCD + Kubernetes).

## Quick Start

```bash
make up        # Start everything (proxy → apps → docs → monitoring)
make down      # Stop everything
make ps        # Show what's running
make help      # List all available targets
```

Start individual stacks:

```bash
make proxy-up        # Traefik reverse proxy (creates the shared network)
make apps-up         # All application services
make docs-up         # Documentation site
make monitoring-up   # Prometheus, Grafana, Alloy, Loki
```

Start/stop a single service:

```bash
make service-up   S=placeholder1-service
make service-down S=placeholder1-service
make service-logs S=placeholder1-service
```

<details>
<summary>Without Make (raw docker compose commands)</summary>

```bash
docker compose -f docker-compose.proxy.yml up -d
docker compose -f docker-compose.applications.yml up -d --build
docker compose -f docker-compose.docs.yml up -d --build
```

Stop:

```bash
docker compose -f docker-compose.proxy.yml down
docker compose -f docker-compose.applications.yml down
docker compose -f docker-compose.docs.yml down
```

</details>

## Makefile Targets

Run `make help` to see all targets. Key ones:

| Target | Description |
|--------|-------------|
| `make up / down / restart` | Full stack lifecycle |
| `make ps` | Show running containers |
| `make logs` | Tail logs for everything |
| `make proxy-up/down/restart/logs` | Manage the Traefik proxy |
| `make apps-up/down/restart/logs/build` | Manage all application services |
| `make service-up/down/restart/logs/build S=<name>` | Manage a single service |
| `make docs-up/down/restart/logs/build` | Manage the documentation site |
| `make monitoring-up/down/restart/logs` | Manage the monitoring stack |
| `make validate` | Validate all compose files |
| `make clean` | Stop everything and remove volumes/images |
| `make pull` | Pull latest images |
| `make network` | Create the shared networks (idempotent) |

## Compose Files

| File | Description |
|------|-------------|
| `docker-compose.proxy.yml` | Traefik reverse proxy + homepage |
| `docker-compose.applications.yml` | All application services (builds from source) |
| `docker-compose.docs.yml` | Documentation site (builds from source) |
| `../observability/docker-compose.yml` | Monitoring stack (Prometheus, Grafana, Alloy, Loki) |

## Structure

```
orchestrators/
├── docker-compose.proxy.yml          # Traefik reverse proxy
├── docker-compose.applications.yml   # All application services
├── docker-compose.docs.yml           # Documentation site
├── proxy/
│   ├── traefik.yml                   # Traefik static configuration
│   ├── dynamic.yml                   # Traefik dynamic routing rules
│   └── homepage/
│       ├── index.html                # Proxy landing page
│       └── 503.html                  # Service unavailable error page
├── Makefile
└── README.md
```

## Architecture

- The **proxy** compose creates the `hobby-internal` and `hobby-external` bridge networks. All other composes join them as external networks.
- **Observability** lives in the separate `observability` repo and connects directly to services via the internal network.
- Use `make service-up S=<name>` to start individual services without spinning up the entire stack.
