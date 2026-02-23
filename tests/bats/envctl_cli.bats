#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  BIN="$REPO_ROOT/bin/envctl"
}

@test "envctl errors when repo cannot be resolved" {
  run bash -lc '
    tmp=$(mktemp -d)
    cd "$tmp" || exit 1
    "$0" doctor
  ' "$BIN"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not resolve repository root"* ]]
}

@test "envctl errors on invalid --repo path" {
  run bash -lc '"$0" --repo /definitely/not/found doctor' "$BIN"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid --repo path"* ]]
}

@test "envctl doctor reports resolved repo and engine path" {
  run bash -lc '
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo/.git" "$tmp/repo/utils"
    cat > "$tmp/repo/utils/run.sh" <<"SCRIPT"
#!/usr/bin/env bash
exit 0
SCRIPT
    chmod +x "$tmp/repo/utils/run.sh"
    "$0" --repo "$tmp/repo" doctor
  ' "$BIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Repo Root:"* ]]
  [[ "$output" == *"Engine Path:"* ]]
  [[ "$output" == *"reachable"* ]]
}

@test "envctl prefers run_engine.sh over run.sh when both exist" {
  run bash -lc '
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo/.git" "$tmp/repo/utils"
    cat > "$tmp/repo/utils/run.sh" <<"SCRIPT"
#!/usr/bin/env bash
echo "from-run-sh"
SCRIPT
    cat > "$tmp/repo/utils/run_engine.sh" <<"SCRIPT"
#!/usr/bin/env bash
echo "from-run-engine"
SCRIPT
    chmod +x "$tmp/repo/utils/run.sh" "$tmp/repo/utils/run_engine.sh"
    "$0" --repo "$tmp/repo" dashboard
  ' "$BIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"from-run-engine"* ]]
  [[ "$output" != *"from-run-sh"* ]]
}

@test "envctl forwards args to repo engine and sets launcher env vars" {
  run bash -lc '
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo/.git" "$tmp/repo/utils"
    cat > "$tmp/repo/utils/run.sh" <<"SCRIPT"
#!/usr/bin/env bash
echo "launcher=${RUN_LAUNCHER_NAME:-}"
echo "context=${RUN_LAUNCHER_CONTEXT:-}"
echo "args:$*"
exit 7
SCRIPT
    chmod +x "$tmp/repo/utils/run.sh"
    "$0" --repo "$tmp/repo" resume trees=true
  ' "$BIN"
  [ "$status" -eq 7 ]
  [[ "$output" == *"launcher=envctl"* ]]
  [[ "$output" == *"context=envctl"* ]]
  [[ "$output" == *"args:resume trees=true"* ]]
}

@test "envctl supports --repo=<path> form" {
  run bash -lc '
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo/.git" "$tmp/repo/utils"
    cat > "$tmp/repo/utils/run.sh" <<"SCRIPT"
#!/usr/bin/env bash
echo "equal-form"
SCRIPT
    chmod +x "$tmp/repo/utils/run.sh"
    "$0" --repo="$tmp/repo" dashboard
  ' "$BIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"equal-form"* ]]
}

@test "envctl auto-detects repo from current directory" {
  run bash -lc '
    tmp=$(mktemp -d)
    mkdir -p "$tmp/repo/.git" "$tmp/repo/utils" "$tmp/repo/sub/dir"
    cat > "$tmp/repo/utils/run.sh" <<"SCRIPT"
#!/usr/bin/env bash
echo "ok-auto"
SCRIPT
    chmod +x "$tmp/repo/utils/run.sh"
    cd "$tmp/repo/sub/dir" || exit 1
    "$0" dashboard
  ' "$BIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok-auto"* ]]
}

@test "envctl install --dry-run prints block and does not mutate shell file" {
  run bash -lc '
    tmp=$(mktemp -d)
    shell_file="$tmp/.zshrc"
    printf "# existing\n" > "$shell_file"
    before=$(cat "$shell_file")
    "$0" install --shell-file "$shell_file" --dry-run
    after=$(cat "$shell_file")
    [ "$before" = "$after" ]
  ' "$BIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"# >>> envctl PATH >>>"* ]]
  [[ "$output" == *"# <<< envctl PATH <<<"* ]]
}

@test "envctl install is idempotent and uninstall removes block" {
  run bash -lc '
    tmp=$(mktemp -d)
    shell_file="$tmp/.zshrc"
    touch "$shell_file"

    "$0" install --shell-file "$shell_file"
    "$0" install --shell-file "$shell_file"

    start_count=$(grep -c "^# >>> envctl PATH >>>$" "$shell_file" || true)
    end_count=$(grep -c "^# <<< envctl PATH <<<$" "$shell_file" || true)
    echo "counts:${start_count}:${end_count}"

    "$0" uninstall --shell-file "$shell_file"
    if [ -s "$shell_file" ]; then
      echo "leftover"
      cat "$shell_file"
      exit 1
    fi
  ' "$BIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"counts:1:1"* ]]
}

@test "envctl --help prints usage" {
  run "$BIN" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"envctl doctor"* ]]
}
