# Planning and Worktrees

## Planning Root Path
Planning commands read files from `ENVCTL_PLANNING_DIR`.

Default:

```bash
ENVCTL_PLANNING_DIR="docs/planning"
```

You can set:
- A repo-relative path (recommended), for example `work/plans`.
- An absolute path.

## Planning Commands

```bash
envctl --plan
envctl --sequential-plan
envctl --parallel-plan
envctl --planning-prs
envctl --keep-plan
```

## Selection Input
When passing plan selections, you can use any of these forms:
- `folder/task`
- `<planning-root>/folder/task`
- absolute path to a plan file

The `.md` suffix is optional.

## Direct Worktree Setup

```bash
envctl --setup-worktrees feature-x 3
envctl --setup-worktree feature-x 2
envctl --include-existing-worktrees 1,3
```

## Typical Loop

```bash
envctl --plan
envctl dashboard
envctl test --all
envctl logs --all --logs-follow
```
