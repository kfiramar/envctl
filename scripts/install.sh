#!/usr/bin/env bash

set -euo pipefail

mode=${1:-}
if [ "$mode" != "install" ] && [ "$mode" != "uninstall" ]; then
    echo "Usage: install.sh <install|uninstall> [--shell-file <path>] [--dry-run]" >&2
    exit 1
fi
shift || true

shell_file="${HOME}/.zshrc"
dry_run=false

while [ $# -gt 0 ]; do
    case "$1" in
        --shell-file)
            shell_file="${2:-}"
            if [ -z "$shell_file" ]; then
                echo "Missing value for --shell-file" >&2
                exit 1
            fi
            shift 2
            ;;
        --shell-file=*)
            shell_file="${1#*=}"
            if [ -z "$shell_file" ]; then
                echo "Missing value for --shell-file" >&2
                exit 1
            fi
            shift
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

block_start="# >>> envctl PATH >>>"
block_end="# <<< envctl PATH <<<"
path_line='export PATH="$HOME/projects/envctl/bin:$PATH"'

mkdir -p "$(dirname "$shell_file")"
if [ ! -f "$shell_file" ]; then
    : > "$shell_file"
fi

remove_block_to_stdout() {
    awk -v start="$block_start" -v end="$block_end" '
        $0 == start {skip=1; next}
        $0 == end {skip=0; next}
        skip != 1 {print}
    ' "$shell_file"
}

if [ "$mode" = "install" ]; then
    if grep -Fqx "$block_start" "$shell_file" 2>/dev/null; then
        exit 0
    fi

    if [ "$dry_run" = true ]; then
        printf '%s\n%s\n%s\n' "$block_start" "$path_line" "$block_end"
        exit 0
    fi

    {
        [ -s "$shell_file" ] && [ "$(tail -c 1 "$shell_file" 2>/dev/null || true)" != "" ] && printf '\n'
        printf '%s\n' "$block_start"
        printf '%s\n' "$path_line"
        printf '%s\n' "$block_end"
    } >> "$shell_file"

    exit 0
fi

# uninstall mode
if ! grep -Fqx "$block_start" "$shell_file" 2>/dev/null; then
    exit 0
fi

if [ "$dry_run" = true ]; then
    remove_block_to_stdout
    exit 0
fi

tmp="$(mktemp)"
remove_block_to_stdout > "$tmp"
mv "$tmp" "$shell_file"
exit 0
