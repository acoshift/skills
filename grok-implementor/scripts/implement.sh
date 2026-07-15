#!/usr/bin/env bash
# Grok implementor: delegate a well-specified implementation task to Grok CLI.
# Always runs grok-4.5.
# Usage:
#   implement.sh <<'PROMPT'
#   ... implementation brief ...
#   PROMPT
#   implement.sh -f brief.md
#   echo "..." | implement.sh

set -euo pipefail

prompt=""
if [[ "${1:-}" == "-f" || "${1:-}" == "--file" ]]; then
  prompt="$(cat "${2:?missing file}")"
elif [[ $# -gt 0 ]]; then
  echo "usage: $0 [-f file | < brief]" >&2
  exit 2
elif [[ ! -t 0 ]]; then
  prompt="$(cat)"
else
  echo "error: provide a brief on stdin or with -f file" >&2
  exit 2
fi

if ! command -v grok >/dev/null 2>&1; then
  echo "error: grok CLI not found on PATH" >&2
  exit 127
fi

exec grok -p "$prompt" \
  --model grok-4.5 \
  --permission-mode acceptEdits \
  --check \
  --output-format plain
