# Troubleshooting

## Could not resolve repository root
- Confirm the path is a git repo root (`.git` dir or file).
- Use `--repo /absolute/path` when running outside the repo tree.

## Port collisions or stale reservations
- Run `envctl --doctor`.
- Run `envctl --clear-port-state`.
- Adjust base ports in `.envctl`.

## Wrong services are starting
- If `ENVCTL_SERVICE_<N>` is set, auto-discovery is disabled.
- Remove/fix explicit service entries.

## Infra not starting as expected
Check toggles:
- `ENVCTL_SKIP_DEFAULT_INFRASTRUCTURE`
- PostgreSQL and Supabase toggles
- `REDIS_*`
- `N8N_*`

## Planning files are not found
- Check `ENVCTL_PLANNING_DIR` in `.envctl`.
- Verify files exist under that directory and are `.md` files.
- Use `envctl --plan` interactively to confirm discovery.
