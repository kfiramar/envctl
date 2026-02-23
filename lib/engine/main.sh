#!/usr/bin/env bash

# Development Server Runner - Flexible Edition
# This script runs frontend and backend servers with proper error handling
#
# Usage:
#   ./run.sh                    # Run main project only (default; configurable via ENVCTL_DEFAULT_MODE)
#   ./run.sh main=true          # Run main project only
#   ./run.sh --main             # Run main project only (explicit)
#   ./run.sh trees=false        # Run main project only
#   MAIN=true ./run.sh          # Alternative way to run main
#   ./run.sh fresh=true         # Force fresh dependency install
#   ./run.sh --batch            # Non-interactive mode
#   ./run.sh -b                 # Non-interactive mode (short)
#   BATCH=true ./run.sh         # Non-interactive via env var
#   ./run.sh force=true         # Force kill processes on default ports
#   ./run.sh --force            # Force mode (short)
#   FORCE=true ./run.sh         # Force mode via env var
#   ./run.sh --resume                    # Resume previous session from saved state
#   ./run.sh --docker                    # Build and run via Docker Compose
#   ./run.sh --stop-docker-on-exit       # Stop Docker if this script started it
#   ./run.sh --setup-worktrees <FEATURE> <COUNT>  # Create worktrees then run them
#   ./run.sh --setup-worktree <FEATURE> <ITER>    # Create one worktree then run it
#   ./run.sh --plan [SELECTION]          # Create worktrees from planning selection and run (parallel by default)
#   ./run.sh --sequential-plan [SELECTION] # Plan mode + one-by-one startup
#   ./run.sh --parallel-plan [SELECTION] # Alias for --plan
#   ./run.sh dashboard         # Show runtime dashboard (services + health + resume hints)
#   ./run.sh dashboard --interactive # Show dashboard then enter interactive command loop
#   ./run.sh delete-worktree         # Interactive worktree cleanup (delete one/all)
#   ./run.sh delete-worktree --all   # Delete all worktrees with confirmation
#   ./run.sh --planning-prs [SELECTION]  # Create PRs from planning selection (no run)
#   ./run.sh --seed-requirements-from-base   # Seed per-tree DB/Redis from base if available
#   ./run.sh --frontend-test-runner bun  # Use bun for frontend tests
#   ./run.sh --fast                     # Enable fast startup caches
#   ./run.sh --refresh-cache            # Force full scan and refresh caches
#   ./run.sh --log-profile info          # Apply log profile (backend + frontend)
#   ./run.sh --log-level debug           # Apply log level (backend + frontend)
#
# Directory Configuration:
#   BACKEND_DIR_NAME=my-backend ./run.sh
#   FRONTEND_DIR_NAME=my-frontend ./run.sh
#   TREES_DIR_NAME=my-trees ./run.sh      # Default: trees
#   BACKEND_PATTERNS="api|backend|server" ./run.sh
#   FRONTEND_PATTERNS="web|frontend|ui" ./run.sh

set -uo pipefail
# Don't exit on error - we want to continue even if some services fail
set +e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/loader.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/config.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/git.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/env.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/ports.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/worktrees.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/pr.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/runtime_map.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/services.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/requirements.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/docker.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/actions.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/ui.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/state.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/analysis.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/planning.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/run_all_trees_helpers.sh"

RUN_SH_DEBUG="${RUN_SH_DEBUG:-false}"
if [ "${RUN_SH_DEBUG}" != true ]; then
    for arg in "$@"; do
        case "$arg" in
            --debug-trace*)
                RUN_SH_DEBUG=true
                break
                ;;
        esac
    done
fi
if [ "$(type -t debug_log_init_prelog)" = "function" ]; then
    debug_log_init_prelog
fi

run_all_trees_init_tty

load_envctl_config "$BASE_DIR"

init_run_all_trees_config "$@"
if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
    debug_args=$(printf '%q ' "${ORIGINAL_ARGS[@]}" | sed 's/ $//')
    debug_log_line "INFO" "cli.parse.start args=${debug_args}"
fi
parse_run_all_trees_args "$@"
set -- "${ORIGINAL_ARGS[@]}"
if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
    debug_log_line "INFO" "cli.parse.end errors=${#RUN_ALL_TREES_ARG_ERRORS[@]}"
fi

if [ ${#RUN_ALL_TREES_ARG_ERRORS[@]} -gt 0 ]; then
    if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
        for err in "${RUN_ALL_TREES_ARG_ERRORS[@]}"; do
            debug_log_line "ERROR" "cli.parse.error=${err}"
        done
        if [ "$(type -t debug_log_finalize)" = "function" ]; then
            debug_log_finalize
        fi
    fi
    run_all_trees_cli_report_errors
    print_run_all_trees_usage
    exit 1
fi

if [ "$SHOW_HELP" = true ]; then
    print_run_all_trees_usage
    exit 0
fi

if [ -n "${RUN_SH_COMMAND:-}" ] && [ "$DOCKER_MODE" = true ]; then
    echo -e "${RED}--command is not supported in Docker mode (deprecated).${NC}"
    exit 2
fi

if [ "${RUN_SH_COMMAND_LIST_COMMANDS:-false}" = true ] || [ "${RUN_SH_COMMAND_LIST_TARGETS:-false}" = true ]; then
    run_all_trees_run_command
    exit $?
fi

if [ -n "${RUN_SH_COMMAND:-}" ]; then
    if [ "${RUN_SH_COMMAND_ONLY:-false}" = true ] || [ "${RUN_SH_COMMAND_RESUME:-false}" = true ] || [ "$RUN_SH_COMMAND" = "stop" ] || [ "$RUN_SH_COMMAND" = "stop-all" ] || [ "$RUN_SH_COMMAND" = "blast-all" ]; then
        run_all_trees_run_command
        exit $?
    fi
fi

if [ -n "${FRONTEND_TEST_RUNNER:-}" ]; then
    export FRONTEND_TEST_RUNNER
fi

if [ "${RUN_SH_REFRESH_CACHE:-false}" = true ]; then
    RUN_SH_FAST_STARTUP=true
fi

RUN_SH_OPT_DISABLE_ALL="${RUN_SH_OPT_DISABLE_ALL:-false}"
RUN_SH_OPT_FAST_WAIT="${RUN_SH_OPT_FAST_WAIT:-${RUN_SH_FAST_WAIT:-false}}"
RUN_SH_OPT_PORT_SNAPSHOT="${RUN_SH_OPT_PORT_SNAPSHOT:-${RUN_SH_PORT_SNAPSHOT:-false}}"
RUN_SH_OPT_FAST_REQUIREMENTS="${RUN_SH_OPT_FAST_REQUIREMENTS:-${RUN_SH_FAST_REQUIREMENTS:-false}}"
RUN_SH_OPT_SKIP_NOOP_DEP_INSTALL="${RUN_SH_OPT_SKIP_NOOP_DEP_INSTALL:-false}"
RUN_SH_OPT_SKIP_NOOP_MIGRATIONS="${RUN_SH_OPT_SKIP_NOOP_MIGRATIONS:-false}"
RUN_SH_OPT_PARALLEL_TREES="${RUN_SH_OPT_PARALLEL_TREES:-false}"
RUN_SH_OPT_PARALLEL_TREES_EXPLICIT="${RUN_SH_OPT_PARALLEL_TREES_EXPLICIT:-false}"
RUN_SH_OPT_PARALLEL_TREES_MAX="${RUN_SH_OPT_PARALLEL_TREES_MAX:-4}"

if [ "${RUN_SH_OPT_DISABLE_ALL}" = true ]; then
    RUN_SH_OPT_FAST_WAIT=false
    RUN_SH_OPT_PORT_SNAPSHOT=false
    RUN_SH_OPT_FAST_REQUIREMENTS=false
    RUN_SH_OPT_SKIP_NOOP_DEP_INSTALL=false
    RUN_SH_OPT_SKIP_NOOP_MIGRATIONS=false
    RUN_SH_OPT_PARALLEL_TREES=false
    RUN_SH_OPT_PARALLEL_TREES_EXPLICIT=false
fi

RUN_SH_FAST_WAIT="$RUN_SH_OPT_FAST_WAIT"
RUN_SH_PORT_SNAPSHOT="$RUN_SH_OPT_PORT_SNAPSHOT"
RUN_SH_FAST_REQUIREMENTS="$RUN_SH_OPT_FAST_REQUIREMENTS"

if [ -z "${RUN_SH_STATUS_CACHE_TTL:-}" ] && [ "${RUN_SH_FAST_STARTUP:-false}" = true ]; then
    RUN_SH_STATUS_CACHE_TTL=5
fi
if [ -z "${RUN_SH_PID_TTL:-}" ]; then
    RUN_SH_PID_TTL=10
fi
if [ -z "${RUN_SH_HEALTH_PARALLEL:-}" ]; then
    RUN_SH_HEALTH_PARALLEL=4
fi

if [ "$(type -t run_sh_runtime_dir)" = "function" ]; then
    RUN_SH_RUNTIME_DIR="$(run_sh_runtime_dir)"
else
    RUN_SH_RUNTIME_DIR="${RUN_SH_RUNTIME_DIR:-/tmp/envctl-runtime}"
    mkdir -p "$RUN_SH_RUNTIME_DIR" 2>/dev/null || true
fi

if [ "${RUN_SH_CLEAR_PORTS:-false}" = true ]; then
    LAST_STATE_FILE="$RUN_SH_RUNTIME_DIR/.last_state"
    cleared_paths=""
    if [ "$(type -t port_state_clear_saved)" = "function" ]; then
        cleared_paths=$(port_state_clear_saved 2>/dev/null || true)
    fi
    if [ -n "$cleared_paths" ]; then
        echo "Cleared saved port state files:"
        while IFS= read -r path; do
            [ -n "$path" ] && echo "  - $path"
        done <<< "$cleared_paths"
    else
        echo "No saved port state files found to clear."
    fi
    exit 0
fi

echo "🚀 Starting environment..."
echo "=================================================="

# Startup timeout (seconds) - extended automatically for fresh installs
if [ -z "${STARTUP_TIMEOUT:-}" ]; then
    if [ "$FRESH_INSTALL" = true ]; then
        STARTUP_TIMEOUT=180
    else
        STARTUP_TIMEOUT=30
    fi
fi

# Colors for output (respect NO_COLOR convention from core.sh)
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    WHITE='\033[0;37m'
    GRAY='\033[0;90m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
fi
LOG_ERROR_PATTERN="(error|exception|failed|critical|traceback|fatal|failure|err:|warn:|warning:|panic|abort|assertion|segfault|stack trace|undefined|null pointer|out of memory)"
LOG_COLORS=("${GREEN}" "${YELLOW}" "${BLUE}" "${CYAN}" "\033[0;35m" "\033[1;32m" "\033[1;33m" "\033[1;34m" "\033[1;36m" "\033[0;33m")

PR_STATUS_TTL="${PR_STATUS_TTL:-30}"
HEALTH_STATUS_TTL="${HEALTH_STATUS_TTL:-120}"
HAS_GH=false
if command -v gh >/dev/null 2>&1; then
    HAS_GH=true
fi
SIGINT_REQUESTED=false

# Directory name configuration
BACKEND_DIR_NAME="${BACKEND_DIR_NAME:-backend}"
FRONTEND_DIR_NAME="${FRONTEND_DIR_NAME:-frontend}"
TREES_DIR_NAME="${TREES_DIR_NAME:-trees}"
DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-$BASE_DIR/docker-compose.yml}"
DOCKER_COMPOSE_OVERRIDE=""
DOCKER_COMPOSE_EXTRA_FILES=()
DOCKER_PROJECT_NAME="${DOCKER_PROJECT_NAME:-$(basename "$BASE_DIR")}"
DOCKER_KNOWN_SERVICES=()

# Auto-detection patterns (used if directories don't exist with exact names)
BACKEND_PATTERNS="${BACKEND_PATTERNS:-backend|api|server}"
FRONTEND_PATTERNS="${FRONTEND_PATTERNS:-frontend|client|web|ui|automation}"

# Configuration
# Using wider spacing to avoid collisions when running many apps
# Backend: 8000, 8020, 8040... Frontend: 9000, 9020, 9040...
BACKEND_PORT_BASE="${BACKEND_PORT_BASE:-8000}"
FRONTEND_PORT_BASE="${FRONTEND_PORT_BASE:-9000}"
PORT_SPACING="${PORT_SPACING:-20}"

# Create logs directory with timestamp under runtime root
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RUN_SH_RUNS_DIR="${RUN_SH_RUNS_DIR:-${RUN_SH_RUNTIME_DIR%/}/runs}"

if [ "${RUN_SH_COMMAND:-}" != "dashboard" ] && [ "${RUN_SH_COMMAND:-}" != "doctor" ] && [ "${RUN_SH_COMMAND:-}" != "delete-worktree" ]; then
    mkdir -p "$RUN_SH_RUNS_DIR"
fi

LOGS_DIR="$RUN_SH_RUNS_DIR/run_$TIMESTAMP"
if [ "${RUN_SH_COMMAND:-}" != "dashboard" ] && [ "${RUN_SH_COMMAND:-}" != "doctor" ] && [ "${RUN_SH_COMMAND:-}" != "delete-worktree" ]; then
    mkdir -p "$LOGS_DIR"
fi
LAST_STATE_FILE="$RUN_SH_RUNTIME_DIR/.last_state"
RUN_SH_STATE_DIR="${RUN_SH_STATE_DIR:-${RUN_SH_RUNTIME_DIR%/}/states}"
if [ "${RUN_SH_COMMAND:-}" != "dashboard" ] && [ "${RUN_SH_COMMAND:-}" != "doctor" ] && [ "${RUN_SH_COMMAND:-}" != "delete-worktree" ]; then
    mkdir -p "$RUN_SH_STATE_DIR"
fi
STATE_FILE="$RUN_SH_STATE_DIR/run_${TIMESTAMP}_$$.state"

if [ "$(type -t debug_log_finalize)" = "function" ] && debug_enabled; then
    debug_log_finalize
    debug_log_header
    debug_capture_env
    debug_capture_git_context
    debug_log_line "INFO" "debug.trace.init log=$(debug_log_path)"
    if [ "${RUN_SH_DEBUG_STDIO:-true}" = true ]; then
        if command -v tee >/dev/null 2>&1; then
            debug_log_line "INFO" "debug.stdio=tee"
            exec > >(tee -a "$(debug_log_path)") 2> >(tee -a "$(debug_log_path)" >&2)
        else
            debug_log_line "WARN" "debug.stdio=fallback"
            exec >>"$(debug_log_path)" 2>&1
        fi
    else
        debug_log_line "INFO" "debug.stdio=disabled"
    fi
    debug_trace_on
fi
if [ "${RUN_SH_COMMAND:-}" != "dashboard" ] && [ "${RUN_SH_COMMAND:-}" != "doctor" ] && [ "${RUN_SH_COMMAND:-}" != "delete-worktree" ]; then
    echo -e "${CYAN}Logs will be saved to: $LOGS_DIR${NC}"
fi

if [ "$(type -t port_state_load_once)" = "function" ]; then
    port_state_load_once
fi

run_all_trees_init_tty_debug_log

if [ "$(type -t profile_start)" = "function" ]; then
    profile_start "preflight"
fi
if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
    debug_log_line "INFO" "preflight.start"
fi

if [ "$FORCE_PORTS" = true ]; then
    echo -e "${YELLOW}⚠️  FORCE MODE ENABLED: Will kill processes on default ports${NC}"
fi

# Arrays to store information
declare -a pids=()
declare -a services=()
declare -A service_info=()  # Detailed service info
declare -A service_ports=()  # Track which ports are used by which services
declare -A actual_ports=()   # Track actual ports after retries
declare -A PR_STATUS_CACHE=()
declare -A PR_STATUS_CACHE_TS=()
declare -A HEALTH_STATUS=()
declare -A HEALTH_STATUS_TS=()
SEED_REQUIREMENTS_ACTIVE=false
SEED_REQUIREMENTS_DB_READY=false
SEED_REQUIREMENTS_DB_VOLUME=""
SEED_REQUIREMENTS_REDIS_READY=false
SEED_REQUIREMENTS_REDIS_VOLUME=""
REDIS_SEED_FILE=""
REDIS_SEED_READY=false
declare -A DOCKER_RESERVED_PORTS=()
declare -a DOCKER_TREE_ENTRIES=()
DOCKER_LOG_FOLLOW_PID=""
declare -a TREES_TARGETS=()
declare -a TREES_TARGET_PATHS=()
declare -a TREES_ROOTS=()
USE_FEATURE_LABELS=false
TREES_FEATURE_FILTER=""
declare -A PLANNING_EXISTING_COUNTS=()
declare -A ATTACH_SERVICE_INFO=()
ATTACH_STATE_ENABLED=false
declare -A SUPABASE_TREE_PUBLIC_URLS=()
declare -A SUPABASE_TREE_PUBLIC_PORTS=()
declare -A SUPABASE_TREE_DB_PORTS=()
declare -A SUPABASE_TREE_DB_PASSWORDS=()
declare -A SUPABASE_TREE_JWT_SECRETS=()
declare -A SUPABASE_TREE_ANON_KEYS=()
declare -A SUPABASE_TREE_SERVICE_ROLE_KEYS=()
declare -A SUPABASE_TREE_PROJECTS=()
declare -A SUPABASE_TREE_NETWORK_NAMES=()
declare -A SUPABASE_TREE_AUTH_RESET_DONE=()
declare -A N8N_TREE_PORTS=()

# Database configuration
DB_CONTAINER_NAME="${DB_CONTAINER_NAME:-${DOCKER_PROJECT_NAME}-postgres}"
REDIS_CONTAINER_NAME="${REDIS_CONTAINER_NAME:-${DOCKER_PROJECT_NAME}-redis}"
DB_PORT="${DB_PORT:-5432}"
REDIS_PORT="${REDIS_PORT:-6379}"
DB_PORT_BASE="${DB_PORT_BASE:-$DB_PORT}"
REDIS_PORT_BASE="${REDIS_PORT_BASE:-$REDIS_PORT}"
POSTGRES_MAIN_ENABLE="${POSTGRES_MAIN_ENABLE:-true}"
REDIS_ENABLE="${REDIS_ENABLE:-true}"
REDIS_MAIN_ENABLE="${REDIS_MAIN_ENABLE:-true}"
REDIS_ALL_TREES="${REDIS_ALL_TREES:-true}"
REDIS_TREE_FILTER="${REDIS_TREE_FILTER:-}"
PER_TREE_REQUIREMENTS="${PER_TREE_REQUIREMENTS:-true}"
SEED_REQUIREMENTS_FROM_BASE="${SEED_REQUIREMENTS_FROM_BASE:-false}"
SEED_REQUIREMENTS_HOST="${SEED_REQUIREMENTS_HOST:-host.docker.internal}"
SEED_REQUIREMENTS_MODE="${SEED_REQUIREMENTS_MODE:-volume}"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
DB_NAME="${DB_NAME:-postgres}"
N8N_PORT_BASE="${N8N_PORT_BASE:-5678}"
SUPABASE_PUBLIC_PORT_BASE="${SUPABASE_PUBLIC_PORT_BASE:-54321}"
SUPABASE_DB_PORT_BASE="${SUPABASE_DB_PORT_BASE:-54322}"
SUPABASE_DB_USER="${SUPABASE_DB_USER:-postgres}"
SUPABASE_DB_NAME="${SUPABASE_DB_NAME:-postgres}"
SUPABASE_MAIN_ENABLE="${SUPABASE_MAIN_ENABLE:-false}"
N8N_ENABLE="${N8N_ENABLE:-true}"
N8N_MAIN_ENABLE="${N8N_MAIN_ENABLE:-false}"
N8N_ALL_TREES="${N8N_ALL_TREES:-false}"
N8N_TREE_FILTER="${N8N_TREE_FILTER:-}"
SUPABASE_ALL_TREES="${SUPABASE_ALL_TREES:-false}"
SUPABASE_TREE_FILTER="${SUPABASE_TREE_FILTER:-}"
REMOVE_DB_VOLUMES="${REMOVE_DB_VOLUMES:-false}"
TIMEOUT_BIN="${TIMEOUT_BIN:-}"
RUN_SH_DOCKER_CMD_TIMEOUT_SEC="${RUN_SH_DOCKER_CMD_TIMEOUT_SEC:-8}"
RUN_SH_DOCKER_PROBE_TIMEOUT_SEC="${RUN_SH_DOCKER_PROBE_TIMEOUT_SEC:-3}"
RUN_SH_DOCKER_COMPOSE_TIMEOUT_SEC="${RUN_SH_DOCKER_COMPOSE_TIMEOUT_SEC:-120}"
RUN_SH_DOCKER_COMPOSE_PROBE_TIMEOUT_SEC="${RUN_SH_DOCKER_COMPOSE_PROBE_TIMEOUT_SEC:-10}"
if [ -z "${RUN_SH_DOCKER_AUTO_RESTART_ON_HANG:-}" ]; then
    # Safety default: never quit/restart Docker Desktop automatically unless explicitly enabled.
    RUN_SH_DOCKER_AUTO_RESTART_ON_HANG=false
fi
RUN_SH_DOCKER_AUTO_RESTART_MAX="${RUN_SH_DOCKER_AUTO_RESTART_MAX:-1}"
RUN_SH_ALLOW_DOCKER_DAEMON_STOP="${RUN_SH_ALLOW_DOCKER_DAEMON_STOP:-false}"
PYTHON_CMD="${PYTHON_CMD:-}"
MAIN_ENV_FILE="${MAIN_ENV_FILE:-}"
MAIN_ENV_FILE_PATH=""
MAIN_FRONTEND_ENV_FILE="${MAIN_FRONTEND_ENV_FILE:-}"
MAIN_FRONTEND_ENV_FILE_PATH=""
BACKEND_ENV_FILE_OVERRIDE=""
FRONTEND_ENV_FILE_OVERRIDE=""
SKIP_LOCAL_DB_ENV=false
ENVCTL_PLANNING_DIR="${ENVCTL_PLANNING_DIR:-docs/planning}"

# State file for preserving session info
GRACEFUL_SHUTDOWN_TIMEOUT=10
SKIP_CLEANUP=false
CLEANUP_DB_MODE="preserve"  # all | preserve | remove-volumes (stop-all sets all)
CLEANUP_STOP_INFRA=false
CLEANUP_KILL_PORT_RANGES=false
CLEANUP_SCOPE_STATE_ONLY=false
CLEANUP_IN_PROGRESS=false
CLEANUP_COMPLETED=false
DOCKER_WAS_STARTED=false
DOCKER_SKIP_DB=false
DOCKER_SKIP_REDIS=false
DOCKER_UP_NO_DEPS=false
declare -a DOCKER_UP_SERVICES=()

# Set cleanup trap once globals are initialized.
# Use signal-specific traps so cleanup knows whether exit was normal or forced.
RUN_SH_SIGNAL_RECEIVED=""
trap 'RUN_SH_SIGNAL_RECEIVED=INT; cleanup' INT
trap 'RUN_SH_SIGNAL_RECEIVED=TERM; cleanup' TERM
trap 'cleanup' EXIT

# Track failed services
declare -a failed_services=()

# Main execution
cd "$SCRIPT_DIR"

if [ "${RUN_SH_DOCTOR:-false}" = true ] || [ "${RUN_SH_COMMAND:-}" = "doctor" ] || [ "${RUN_SH_COMMAND:-}" = "dashboard" ] || [ "${RUN_SH_COMMAND:-}" = "delete-worktree" ]; then
    SKIP_CLEANUP=true
    run_all_trees_run_command
    exit $?
fi

# Handle special restart-single command (used by recovery script)
if [ $# -gt 0 ] && [ "$1" = "restart-single" ] && [ $# -ge 5 ]; then
    name=$2
    dir=$3
    type=$4
    port=$5
    backend_port=${6:-}

    tree_root=""
    if [ -n "$dir" ]; then
        tree_root=$(dirname "$dir")
    fi
    if [ -n "$tree_root" ] && worktree_identity_from_dir "$tree_root" "$BASE_DIR" "$TREES_DIR_NAME" >/dev/null 2>&1; then
        TREES_MODE=true
    fi

    if [ "$type" = "backend" ]; then
        db_port=""
        redis_port=""
        if per_tree_requirements_enabled; then
            req_ports=$(tree_requirement_ports_for_dir "$tree_root" "$port")
            IFS='|' read -r db_port redis_port <<< "$req_ports"
            if [ -n "$db_port" ] && [ -n "$redis_port" ]; then
                if ! ensure_tree_requirements "$tree_root" "$db_port" "$redis_port"; then
                    echo -e "${RED}Failed to start requirements for ${name}${NC}"
                    exit 1
                fi
            fi
        fi

        if per_tree_requirements_enabled; then
            with_tree_db_overrides "$tree_root" start_service_with_retry "$name" "$dir" "$type" "$port" "" "" "$db_port" "$redis_port"
        else
            start_service_with_retry "$name" "$dir" "$type" "$port" "" "" "$db_port" "$redis_port"
        fi
        exit $?
    fi

    start_service_with_retry "$name" "$dir" "$type" "$port" "$backend_port"
    exit $?
fi

if [ "$SETUP_WORKTREES" = true ]; then
    if ! run_all_trees_handle_setup_worktrees; then
        exit 1
    fi
fi

if [ "$PLANNING_ENVS" = true ]; then
    run_all_trees_handle_planning_envs
    rc=$?
    if [ "$rc" -eq 3 ]; then
        exit 1
    fi
    if [ "$rc" -eq 2 ]; then
        exit 0
    fi
fi

if ! run_all_trees_apply_cli_project_filters; then
    exit 1
fi

run_all_trees_handle_resume

if run_all_trees_handle_docker_mode; then
    exit "${RUN_ALL_TREES_EXIT_STATUS:-0}"
fi

if [ "$(type -t profile_end)" = "function" ]; then
    profile_end "preflight"
fi
if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
    debug_log_line "INFO" "preflight.end"
fi

# Start Docker containers first
echo -e "${CYAN}Starting infrastructure services...${NC}\n"

if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
    debug_log_line "INFO" "requirements.prepare.start"
fi
if ! run_all_trees_prepare_requirements; then
    if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
        debug_log_line "ERROR" "requirements.prepare.failed"
    fi
    exit 1
fi
if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
    debug_log_line "INFO" "requirements.prepare.end"
fi

run_all_trees_resolve_main_environment

if [ "$(type -t profile_start)" = "function" ]; then
    profile_start "requirements_start"
fi
if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
    debug_log_line "INFO" "requirements.start"
fi
if ! run_all_trees_start_requirements; then
    if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
        debug_log_line "ERROR" "requirements.failed"
    fi
    if [ "$(type -t run_all_trees_print_logs_path_once)" = "function" ]; then
        run_all_trees_print_logs_path_once
    fi
    exit 1
fi
if [ "$(type -t profile_end)" = "function" ]; then
    profile_end "requirements_start"
fi
if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
    debug_log_line "INFO" "requirements.end"
fi

echo -e "\n${GREEN}✓ Infrastructure services ready${NC}\n"

if [ "$(type -t debug_log_line)" = "function" ] && debug_enabled; then
    debug_log_line "INFO" "projects.start mode=${TREES_MODE:-false}"
fi
if ! run_all_trees_start_projects; then
    if [ "$(type -t run_all_trees_print_logs_path_once)" = "function" ]; then
        run_all_trees_print_logs_path_once
    fi
    exit 1
fi

if [ "$(type -t run_cache_save)" = "function" ]; then
    run_cache_save
fi
if [ "$(type -t profile_dump_counters)" = "function" ]; then
    profile_dump_counters
fi

write_runtime_map

if [ -n "${RUN_SH_COMMAND:-}" ]; then
    run_all_trees_run_command
    exit $?
fi

if [ "$INTERACTIVE_MODE" != true ]; then
    if ! run_all_trees_print_noninteractive_summary; then
        exit 1
    fi
fi

# Start interactive mode if requested
if [ "$INTERACTIVE_MODE" = true ] && [ "$(type -t debug_enabled)" = "function" ] && debug_enabled; then
    if [ "${RUN_SH_DEBUG_TRACE_INTERACTIVE:-true}" != true ]; then
        debug_log_line "INFO" "debug.trace.interactive=disabled"
        debug_trace_off
    fi
fi
if run_all_trees_run_interactive; then
    # After quitting interactive mode, we're done
    exit 0
fi

# Keep script running
wait
