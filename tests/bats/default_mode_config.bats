#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  CLI_LIB="$REPO_ROOT/lib/engine/lib/run_all_trees_cli.sh"
}

@test "default mode is main when ENVCTL_DEFAULT_MODE is unset" {
  run bash -lc '
    unset ENVCTL_DEFAULT_MODE TREES MAIN
    source "$0"
    run_all_trees_cli_init_config
    run_all_trees_cli_parse_args
    echo "trees=$TREES_MODE main=$MAIN_MODE errs=${#RUN_ALL_TREES_ARG_ERRORS[@]}"
  ' "$CLI_LIB"

  [ "$status" -eq 0 ]
  [[ "$output" == *"trees=false main=true errs=0"* ]]
}

@test "ENVCTL_DEFAULT_MODE=trees sets trees mode by default" {
  run bash -lc '
    unset TREES MAIN
    ENVCTL_DEFAULT_MODE=trees
    source "$0"
    run_all_trees_cli_init_config
    run_all_trees_cli_parse_args
    echo "trees=$TREES_MODE main=$MAIN_MODE errs=${#RUN_ALL_TREES_ARG_ERRORS[@]}"
  ' "$CLI_LIB"

  [ "$status" -eq 0 ]
  [[ "$output" == *"trees=true main=false errs=0"* ]]
}

@test "explicit --main overrides ENVCTL_DEFAULT_MODE=trees" {
  run bash -lc '
    unset TREES MAIN
    ENVCTL_DEFAULT_MODE=trees
    source "$0"
    run_all_trees_cli_init_config --main
    run_all_trees_cli_parse_args --main
    echo "trees=$TREES_MODE main=$MAIN_MODE errs=${#RUN_ALL_TREES_ARG_ERRORS[@]}"
  ' "$CLI_LIB"

  [ "$status" -eq 0 ]
  [[ "$output" == *"trees=false main=true errs=0"* ]]
}

@test "invalid ENVCTL_DEFAULT_MODE reports parse error and falls back to main" {
  run bash -lc '
    unset TREES MAIN
    ENVCTL_DEFAULT_MODE=invalid
    source "$0"
    run_all_trees_cli_init_config
    run_all_trees_cli_parse_args
    echo "trees=$TREES_MODE main=$MAIN_MODE errs=${#RUN_ALL_TREES_ARG_ERRORS[@]}"
    printf "%s\n" "${RUN_ALL_TREES_ARG_ERRORS[@]}"
  ' "$CLI_LIB"

  [ "$status" -eq 0 ]
  [[ "$output" == *"trees=false main=true errs=1"* ]]
  [[ "$output" == *"Invalid ENVCTL_DEFAULT_MODE"* ]]
}
