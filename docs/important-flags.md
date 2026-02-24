# Important Flags

These are the highest-value flags for daily use.

## Session and Mode
| Flag | Purpose |
| --- | --- |
| `--resume` | Resume previous runtime state and session mapping quickly. |
| `--batch` | Non-interactive startup and execution. |
| `--main` | Run main mode only (skip trees). |
| `--tree` / `--trees` / `trees=true` / `trees=false` | Explicit tree mode switch. |
| `--doctor` | Run diagnostics and exit. |
| `--dashboard` | Show runtime dashboard and exit. |

Config note: `ENVCTL_DEFAULT_MODE` sets default startup mode when no mode flag is passed.
Allowed values are `main` and `trees` (default: `main`).

## Targeting
| Flag | Purpose |
| --- | --- |
| `--project <name>` | Target one project (repeatable). |
| `--projects <a,b>` | Target multiple projects. |
| `--service <name>` | Target one service. |
| `--all` | Target all projects/services. |
| `--untested` | Target untested projects for test workflows. |

## Worktree Orchestration
| Flag | Purpose |
| --- | --- |
| `--plan [SELECTION]` | Create worktrees from planning selection and run (parallel). |
| `--sequential-plan [SELECTION]` | Plan and run one-by-one. |
| `--parallel-plan [SELECTION]` | Alias for `--plan`. |
| `--setup-worktrees <FEATURE> <COUNT>` | Create multiple worktrees directly. |
| `--setup-worktree <FEATURE> <ITER>` | Create one worktree iteration directly. |
| `--include-existing-worktrees <a,b>` | Include specific existing iterations. |
| `--keep-plan` | Keep planning files in place after execution. |

## Performance and Reliability
| Flag | Purpose |
| --- | --- |
| `--fast` | Enable startup caches. |
| `--refresh-cache` | Force full scan and refresh cached metadata. |
| `--parallel-trees` | Enable parallel tree startup workers. |
| `--parallel-trees-max <n>` | Max parallel tree startup workers. |
| `--clear-port-state` | Clear saved port reservations/state. |
| `--force` | Free configured ports if needed. |

## Logs and Debugging
| Flag | Purpose |
| --- | --- |
| `--logs-tail <n>` | Tail last N lines for logs command. |
| `--logs-follow` | Follow logs continuously. |
| `--logs-duration <sec>` | Follow logs for a fixed duration. |
| `--debug-trace` | Enable trace logging. |
| `--debug-trace-log <path>` | Write trace output to a specific path. |

## Main Infra Source
| Flag | Purpose |
| --- | --- |
| `--main-services-local` | Force local main infra mode. |
| `--main-services-remote` | Force remote main service mode via main env files. |
| `--seed-requirements-from-base` | Seed tree DB/Redis state from base where supported. |

## Planning Path Config
Use `ENVCTL_PLANNING_DIR` in `.envctl` to change where planning files are read from.
Default is `docs/planning`.
