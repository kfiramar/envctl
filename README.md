# envctl

`envctl` is a generic, dynamic CLI orchestration tool for local development environments. It allows you to define, run, and manage multi-service architectures directly from your shell without needing to maintain massive custom Bash scripts for every project.

By creating a simple `.envctl.sh` file in your repository, you can hook into a powerful generic engine that provides instant access to parallel service startup, log multiplexing, health checks, test running, and interactive dashboards.

## Features

- **Project Agnostic:** Runs any project that implements an `.envctl.sh` configuration file.
- **Service Orchestration:** Handles process lifecycle, port allocation, and interactive dashboard multiplexing.
- **Infrastructure Setup:** Can automatically bootstrap PostgreSQL/Redis dependencies or use custom hooks.
- **Testing:** Built-in test runner for orchestrating parallel backend/frontend test suites.
- **Port Conflict Management:** Gracefully detects and handles colliding ports or orphaned containers.
- **Legacy Compatibility:** Seamlessly acts as the vendored `utils/run.sh` script for older Supportopia repositories.

## Quick Start

### 1. Install `envctl`
Run `envctl install` to idempotently add the orchestration tool to your `PATH`.
```bash
./bin/envctl install
```

### 2. Configure Your Project
Create an `.envctl` configuration file at the root of your project: (You can copy `.envctl.example` as a starting point).

```bash
# .envctl

# Optional: Disable the default built-in Docker infrastructure (PostgreSQL, Redis)
ENVCTL_SKIP_DEFAULT_INFRASTRUCTURE=true

# Required: Define the explicit services to start natively inside the generic engine
ENVCTL_SERVICE_1="API Server | server | backend  | 8000 |      | logs/api"
ENVCTL_SERVICE_2="Web App    | client | frontend | 3000 | 8000 | logs/web"
```

### Advanced Variables
You can cleanly define orchestration variables directly in `.envctl`. If you define explicit `ENVCTL_SERVICE_` array items, you can ignore the auto-discovery directory variables.

| Variable | Default | Description |
| --- | --- | --- |
| `ENVCTL_SERVICE_<N>` | Empty | Explicit array string of services to run. Disables implicit auto-discovery overrides. |
| `DB_PORT` / `REDIS_PORT` | `5432` / `6379` | Core default dependency ports. |
| `SUPABASE_MAIN_ENABLE` | `false` | Set to true to automatically bind and start Supabase dependencies. |
| `N8N_MAIN_ENABLE` | `false` | Set to true to automatically orchestrate an n8n environment. |
| `RUN_BACKEND` / `RUN_FRONTEND` | `true` | Implicitly run auto-discovered backend/frontend directories. |
| `BACKEND_DIR_NAME` / `FRONTEND_DIR_NAME` | `backend` / `frontend` | Names for implicit pattern auto-discovery if `ENVCTL_SERVICE_` is explicitly empty. |

### 3. Run Your Environment
Start the interactive dashboard from anywhere inside your repository:
```bash
$ envctl
```

You can also run specific commands:
```bash
$ envctl doctor   # Runs environment diagnostics
$ envctl stop-all # Stops all mapped services
$ envctl test     # Runs the tests
```

## Advanced Configuration Hooks

Your `.envctl.sh` file is evaluated in the context of the `envctl` orchestration engine. You can implement several bash functions to override default system behavior:

| Hook Function | Description |
| --- | --- |
| `envctl_define_services` | The primary entry point. Put all your `start_service_with_retry` calls here. |
| `envctl_setup_infrastructure` | Used to provision databases, caches, or cloud emulators before services start. |

## Migrating from Supportopia
`envctl` retains backward compatibility with older `supportopia` projects via its adapter architecture. If `envctl` is run inside a Supportopia-shaped repository (containing `backend/` and `frontend/` folders) that lacks an `.envctl.sh` file, it will invoke a packaged legacy Supportopia engine adapter seamlessly.

## Local Commands & Diagnostics
- `envctl --list-commands`: See all available commands (dashboard, tests, logs, delete-worktrees, etc).
- `envctl doctor`: Prints information on running orphaned containers, active PIDs, and diagnostic network bounds.
- `envctl uninstall`: Safely removes `envctl` from your `PATH`.
