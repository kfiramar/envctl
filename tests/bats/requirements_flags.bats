#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  REQUIREMENTS_CORE="$REPO_ROOT/lib/engine/lib/requirements_core.sh"
  REQUIREMENTS_SUPABASE="$REPO_ROOT/lib/engine/lib/requirements_supabase.sh"
  BASH_BIN="$(command -v bash || true)"
}

@test "start_postgres skips when POSTGRES_MAIN_ENABLE=false" {
  [ -n "$BASH_BIN" ] || skip "bash not found"
  "$BASH_BIN" -lc 'declare -A __bats_assoc_test=()' >/dev/null 2>&1 || skip "bash with associative arrays required"
  run "$BASH_BIN" -lc '
    set -euo pipefail
    source "$1"
    YELLOW=""
    GREEN=""
    BLUE=""
    RED=""
    NC=""
    ENVCTL_SKIP_DEFAULT_INFRASTRUCTURE=false
    POSTGRES_MAIN_ENABLE=false
    DB_CONTAINER_NAME="envctl-test-postgres"
    DB_PORT=5432
    DB_USER=postgres
    DB_PASSWORD=postgres
    DB_NAME=postgres
    requirements_docker_cmd() {
      echo "docker-called"
      return 1
    }

    start_postgres
  ' _ "$REQUIREMENTS_CORE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping PostgreSQL container start (POSTGRES_MAIN_ENABLE=false)"* ]]
  [[ "$output" != *"docker-called"* ]]
}

@test "start_redis skips when REDIS_MAIN_ENABLE=false" {
  [ -n "$BASH_BIN" ] || skip "bash not found"
  "$BASH_BIN" -lc 'declare -A __bats_assoc_test=()' >/dev/null 2>&1 || skip "bash with associative arrays required"
  run "$BASH_BIN" -lc '
    set -euo pipefail
    source "$1"
    YELLOW=""
    GREEN=""
    BLUE=""
    RED=""
    NC=""
    ENVCTL_SKIP_DEFAULT_INFRASTRUCTURE=false
    REDIS_MAIN_ENABLE=false
    REDIS_CONTAINER_NAME="envctl-test-redis"
    REDIS_PORT=6379
    requirements_docker_cmd() {
      echo "docker-called"
      return 1
    }

    start_redis
  ' _ "$REQUIREMENTS_CORE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping Redis container start (REDIS_MAIN_ENABLE=false)"* ]]
  [[ "$output" != *"docker-called"* ]]
}

@test "start_redis skips when REDIS_ENABLE=false" {
  [ -n "$BASH_BIN" ] || skip "bash not found"
  "$BASH_BIN" -lc 'declare -A __bats_assoc_test=()' >/dev/null 2>&1 || skip "bash with associative arrays required"
  run "$BASH_BIN" -lc '
    set -euo pipefail
    source "$1"
    YELLOW=""
    GREEN=""
    BLUE=""
    RED=""
    NC=""
    ENVCTL_SKIP_DEFAULT_INFRASTRUCTURE=false
    REDIS_ENABLE=false
    REDIS_MAIN_ENABLE=true
    REDIS_CONTAINER_NAME="envctl-test-redis"
    REDIS_PORT=6379
    requirements_docker_cmd() {
      echo "docker-called"
      return 1
    }

    start_redis
  ' _ "$REQUIREMENTS_CORE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping Redis container start (REDIS_ENABLE=false)"* ]]
  [[ "$output" != *"docker-called"* ]]
}

@test "tree_uses_redis respects global REDIS_ENABLE toggle" {
  [ -n "$BASH_BIN" ] || skip "bash not found"
  "$BASH_BIN" -lc 'declare -A __bats_assoc_test=()' >/dev/null 2>&1 || skip "bash with associative arrays required"
  run "$BASH_BIN" -lc '
    set -euo pipefail
    source "$1"
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo"
    BASE_DIR="$tmp/repo"
    REDIS_ENABLE=false
    REDIS_MAIN_ENABLE=true
    if tree_uses_redis "$tmp/repo"; then
      echo "enabled"
    else
      echo "disabled"
    fi
  ' _ "$REQUIREMENTS_CORE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}

@test "tree_uses_redis disables main when REDIS_MAIN_ENABLE=false" {
  [ -n "$BASH_BIN" ] || skip "bash not found"
  "$BASH_BIN" -lc 'declare -A __bats_assoc_test=()' >/dev/null 2>&1 || skip "bash with associative arrays required"
  run "$BASH_BIN" -lc '
    set -euo pipefail
    source "$1"
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo"
    BASE_DIR="$tmp/repo"
    REDIS_ENABLE=true
    REDIS_MAIN_ENABLE=false
    if tree_uses_redis "$tmp/repo"; then
      echo "enabled"
    else
      echo "disabled"
    fi
  ' _ "$REQUIREMENTS_CORE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}

@test "tree_uses_redis supports tree filters and all-trees override" {
  [ -n "$BASH_BIN" ] || skip "bash not found"
  "$BASH_BIN" -lc 'declare -A __bats_assoc_test=()' >/dev/null 2>&1 || skip "bash with associative arrays required"
  run "$BASH_BIN" -lc '
    set -euo pipefail
    source "$1"
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo/tree-alpha"
    BASE_DIR="$tmp/repo"
    REDIS_ENABLE=true
    REDIS_MAIN_ENABLE=false
    REDIS_ALL_TREES=false
    REDIS_TREE_FILTER="tree-alpha"
    if tree_uses_redis "$tmp/repo/tree-alpha"; then
      echo "filter-enabled"
    else
      echo "filter-disabled"
    fi
    REDIS_TREE_FILTER="other-tree"
    if tree_uses_redis "$tmp/repo/tree-alpha"; then
      echo "mismatch-enabled"
    else
      echo "mismatch-disabled"
    fi
    REDIS_ALL_TREES=true
    REDIS_TREE_FILTER="other-tree"
    if tree_uses_redis "$tmp/repo/tree-alpha"; then
      echo "all-trees-enabled"
    else
      echo "all-trees-disabled"
    fi
  ' _ "$REQUIREMENTS_CORE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"filter-enabled"* ]]
  [[ "$output" == *"mismatch-disabled"* ]]
  [[ "$output" == *"all-trees-enabled"* ]]
}

@test "tree_uses_n8n respects global N8N_ENABLE toggle" {
  [ -n "$BASH_BIN" ] || skip "bash not found"
  "$BASH_BIN" -lc 'declare -A __bats_assoc_test=()' >/dev/null 2>&1 || skip "bash with associative arrays required"
  run "$BASH_BIN" -lc '
    set -euo pipefail
    source "$1"
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo"
    cat > "$tmp/repo/docker-compose.yml" <<YAML
services:
  n8n:
    image: n8nio/n8n
YAML
    BASE_DIR="$tmp/repo"
    N8N_ENABLE=false
    N8N_MAIN_ENABLE=true
    if tree_uses_n8n "$tmp/repo"; then
      echo "enabled"
    else
      echo "disabled"
    fi
  ' _ "$REQUIREMENTS_SUPABASE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}

@test "tree_uses_n8n disables main when N8N_MAIN_ENABLE=false" {
  [ -n "$BASH_BIN" ] || skip "bash not found"
  "$BASH_BIN" -lc 'declare -A __bats_assoc_test=()' >/dev/null 2>&1 || skip "bash with associative arrays required"
  run "$BASH_BIN" -lc '
    set -euo pipefail
    source "$1"
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo"
    cat > "$tmp/repo/docker-compose.yml" <<YAML
services:
  n8n:
    image: n8nio/n8n
YAML
    BASE_DIR="$tmp/repo"
    N8N_ENABLE=true
    N8N_MAIN_ENABLE=false
    if tree_uses_n8n "$tmp/repo"; then
      echo "enabled"
    else
      echo "disabled"
    fi
  ' _ "$REQUIREMENTS_SUPABASE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}

@test "tree_uses_n8n supports tree filters and all-trees override" {
  [ -n "$BASH_BIN" ] || skip "bash not found"
  "$BASH_BIN" -lc 'declare -A __bats_assoc_test=()' >/dev/null 2>&1 || skip "bash with associative arrays required"
  run "$BASH_BIN" -lc '
    set -euo pipefail
    trim() {
      local s="${1:-}"
      s="${s#"${s%%[![:space:]]*}"}"
      s="${s%"${s##*[![:space:]]}"}"
      printf "%s" "$s"
    }
    source "$1"
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo/tree-alpha"
    cat > "$tmp/repo/tree-alpha/docker-compose.yml" <<YAML
services:
  n8n:
    image: n8nio/n8n
YAML
    BASE_DIR="$tmp/repo"
    N8N_ENABLE=true
    N8N_MAIN_ENABLE=false
    N8N_ALL_TREES=false
    N8N_TREE_FILTER="tree-alpha"
    if tree_uses_n8n "$tmp/repo/tree-alpha"; then
      echo "filter-enabled"
    else
      echo "filter-disabled"
    fi
    N8N_TREE_FILTER="other-tree"
    if tree_uses_n8n "$tmp/repo/tree-alpha"; then
      echo "mismatch-enabled"
    else
      echo "mismatch-disabled"
    fi
    N8N_ALL_TREES=true
    N8N_TREE_FILTER="other-tree"
    if tree_uses_n8n "$tmp/repo/tree-alpha"; then
      echo "all-trees-enabled"
    else
      echo "all-trees-disabled"
    fi
  ' _ "$REQUIREMENTS_SUPABASE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"filter-enabled"* ]]
  [[ "$output" == *"mismatch-disabled"* ]]
  [[ "$output" == *"all-trees-enabled"* ]]
}
