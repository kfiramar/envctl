#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  PLANNING_LIB="$REPO_ROOT/lib/engine/lib/planning.sh"
}

@test "list_planning_files honors ENVCTL_PLANNING_DIR" {
  run bash -lc '
    tmp=$(mktemp -d)
    repo="$tmp/repo"
    mkdir -p "$repo/work/plans/backend" "$repo/work/plans/Done/backend"
    printf "# task\n" > "$repo/work/plans/backend/task.md"
    printf "# done\n" > "$repo/work/plans/Done/backend/old.md"

    BASE_DIR="$repo"
    ENVCTL_PLANNING_DIR="work/plans"

    source "$0"
    list_planning_files
  ' "$PLANNING_LIB"

  [ "$status" -eq 0 ]
  [ "$output" = "backend/task.md" ]
}

@test "resolve_planning_files accepts configured path prefixes" {
  run bash -lc '
    tmp=$(mktemp -d)
    repo="$tmp/repo"
    mkdir -p "$repo/work/plans/backend"
    printf "# task\n" > "$repo/work/plans/backend/task.md"

    BASE_DIR="$repo"
    ENVCTL_PLANNING_DIR="work/plans"

    trim() {
      local s="${1:-}"
      s="${s#"${s%%[![:space:]]*}"}"
      s="${s%"${s##*[![:space:]]}"}"
      printf '%s' "$s"
    }

    source "$0"
    resolve_planning_files "work/plans/backend/task,backend/task,$repo/work/plans/backend/task.md"
  ' "$PLANNING_LIB"

  [ "$status" -eq 0 ]
  [ "$output" = "backend/task.md|3" ]
}

@test "planning_move_to_done uses ENVCTL_PLANNING_DIR" {
  run bash -lc '
    tmp=$(mktemp -d)
    repo="$tmp/repo"
    mkdir -p "$repo/work/plans/backend"
    printf "# task\n" > "$repo/work/plans/backend/task.md"

    BASE_DIR="$repo"
    ENVCTL_PLANNING_DIR="work/plans"

    source "$0"
    planning_move_to_done "backend/task.md"

    [ ! -f "$repo/work/plans/backend/task.md" ]
    [ -f "$repo/work/plans/Done/backend/task.md" ]
  ' "$PLANNING_LIB"

  [ "$status" -eq 0 ]
}
