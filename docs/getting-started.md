# Getting Started

## 1. Install

From this repository:

```bash
./bin/envctl install
```

Optional:

```bash
envctl install --shell-file ~/.zshrc
envctl install --shell-file ~/.bashrc
envctl install --dry-run
```

Uninstall:

```bash
envctl uninstall
envctl uninstall --shell-file ~/.zshrc
```

## 2. Verify

```bash
envctl --help
envctl doctor --repo /absolute/path/to/repo
```

## 3. Repository Detection

A valid repo root is any git repository root (`.git` directory or `.git` file).

You can run:
- Inside any subdirectory of a repo (auto-detection).
- From anywhere with `--repo <path>`.

## 4. Optional Project Config

```bash
cp .envctl.example /path/to/your-project/.envctl
```

Default startup mode is `main`. To change default startup to tree mode:

```bash
# .envctl
ENVCTL_DEFAULT_MODE="trees"
```

Minimal explicit services example:

```bash
# .envctl
ENVCTL_SERVICE_1="API Server | backend  | backend  | 8000 |      | logs/api"
ENVCTL_SERVICE_2="Web App    | frontend | frontend | 3000 | 8000 | logs/web"
```

Service format:

```text
"DisplayName | DirectoryPath | ServiceType | Port | BackendPort | LogDirectory"
```

## 5. Start and Operate

```bash
envctl --resume
envctl dashboard
envctl logs --all --logs-follow
envctl test --all
envctl stop-all
```

## 6. How to Use (Recommended)

Start from planning files and run `--plan` first.

1. Put plan files under `ENVCTL_PLANNING_DIR` (default: `docs/planning`).
2. Run `envctl --plan` to create/start worktrees from those plans.
3. Use dashboard, logs, and tests to inspect and compare results.

Example:

```bash
mkdir -p docs/planning/backend
cat > docs/planning/backend/checkout.md <<'PLAN'
# Checkout Implementation Plan
PLAN

envctl --plan
envctl dashboard
```
