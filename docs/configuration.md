# Configuration

## Model

Configuration precedence:
1. Existing shell environment variables.
2. `.envctl` / `.envctl.sh`.
3. Engine defaults.

Use `.envctl` for orchestration behavior.
Use `.env` for app runtime variables and secrets.

## Core
| Variable | Default | Purpose |
| --- | --- | --- |
| `ENVCTL_SKIP_DEFAULT_INFRASTRUCTURE` | `false` | Global skip for built-in PostgreSQL and Redis startup. |
| `ENVCTL_DEFAULT_MODE` | `main` | Startup default when no mode flag is passed (`main` or `trees`). |
| `ENVCTL_PLANNING_DIR` | `docs/planning` | Planning root used by `--plan`, `--sequential-plan`, and `--planning-prs`. |
| `ENVCTL_CONFIG_FILE` | unset | Explicit config file path override. |

## Database (PostgreSQL and Supabase)
Supabase includes PostgreSQL, so treat them as alternative stacks per scope.

| Variable | Default | Purpose |
| --- | --- | --- |
| `POSTGRES_MAIN_ENABLE` | `true` | Enable PostgreSQL for Main mode. |
| `DB_PORT` | `5432` | PostgreSQL base port. |
| `DB_USER` | `postgres` | PostgreSQL user. |
| `DB_PASSWORD` | `postgres` | PostgreSQL password. |
| `DB_NAME` | `postgres` | PostgreSQL DB name. |
| `SUPABASE_MAIN_ENABLE` | `false` | Enable Supabase stack for Main mode. |
| `SUPABASE_ALL_TREES` | `false` | Enable Supabase stack for all trees. |
| `SUPABASE_TREE_FILTER` | empty | Comma-separated features that should use Supabase. |

## Redis
| Variable | Default | Purpose |
| --- | --- | --- |
| `REDIS_ENABLE` | `true` | Global Redis switch (Main + Trees). |
| `REDIS_MAIN_ENABLE` | `true` | Redis switch for Main mode. |
| `REDIS_ALL_TREES` | `true` | Enable Redis in all tree workspaces. |
| `REDIS_TREE_FILTER` | empty | Comma-separated features that should use Redis. |
| `REDIS_PORT` | `6379` | Redis base port. |

## n8n
| Variable | Default | Purpose |
| --- | --- | --- |
| `N8N_ENABLE` | `true` | Global n8n switch (Main + Trees). |
| `N8N_MAIN_ENABLE` | `false` | Enable n8n for Main mode. |
| `N8N_ALL_TREES` | `false` | Enable n8n for all trees. |
| `N8N_TREE_FILTER` | empty | Comma-separated features that should use n8n. |
| `N8N_PORT_BASE` | `5678` | n8n base port. |

## Service Discovery
| Variable | Default | Purpose |
| --- | --- | --- |
| `RUN_BACKEND` | `true` | Enable backend auto-discovery. |
| `BACKEND_DIR_NAME` | `backend` | Preferred backend directory name. |
| `BACKEND_PORT_BASE` | `8000` | Backend base port for allocation. |
| `RUN_FRONTEND` | `true` | Enable frontend auto-discovery. |
| `FRONTEND_DIR_NAME` | `frontend` | Preferred frontend directory name. |
| `FRONTEND_PORT_BASE` | `9000` | Frontend base port for allocation. |
| `ENVCTL_SERVICE_<N>` | empty | Explicit service list; disables auto-discovery when set. |

## Optional Hooks (`.envctl.sh`)
Use hooks only for advanced custom orchestration.

Supported hooks:
- `envctl_define_services`
- `envctl_setup_infrastructure`
