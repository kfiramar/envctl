# Architecture

`envctl` is split into a launcher and an engine.

- Launcher: resolves repo context, installs PATH entry, forwards commands.
- Engine: runs orchestration for services, infrastructure, logs, state, health, and diagnostics.

```mermaid
flowchart LR
  A["User / AI Agent"] --> B["envctl Launcher"]
  B --> C["Git Repo Resolution"]
  C --> D["envctl Engine"]
  D --> E["Services (backend/frontend)"]
  D --> F["Infrastructure (PostgreSQL/Redis/Supabase/n8n)"]
  D --> G["State, Logs, Health, Doctor"]
```

## Determinism
Determinism comes from:
- Consistent CLI entrypoint (`envctl`).
- Explicit mode/target flags.
- Config precedence (`env > .envctl/.envctl.sh > defaults`).
- Saved runtime state with resume flows.
