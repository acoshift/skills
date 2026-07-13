#!/usr/bin/env bash
# Advisor consult: Claude CLI (Fable) read-only second opinion.
# Usage:
#   consult.sh [high|xhigh|max] <<'PROMPT'
#   ... consultation brief ...
#   PROMPT
#   consult.sh xhigh -f brief.md
#   echo "..." | consult.sh high

set -euo pipefail

effort="${1:-xhigh}"
shift || true

case "$effort" in
  high|xhigh|max) ;;
  -f|--file)
    # allow: consult.sh -f file (default effort)
    set -- "$effort" "$@"
    effort="xhigh"
    ;;
  *)
    echo "usage: $0 [high|xhigh|max] [-f file | < brief]" >&2
    exit 2
    ;;
esac

prompt=""
if [[ "${1:-}" == "-f" || "${1:-}" == "--file" ]]; then
  prompt="$(cat "${2:?missing file}")"
elif [[ ! -t 0 ]]; then
  prompt="$(cat)"
else
  echo "error: provide a brief on stdin or with -f file" >&2
  exit 2
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "error: claude CLI not found on PATH" >&2
  exit 127
fi

sys_prompt='You are a senior technical advisor consulted by Grok (another coding agent).
Consultation only: advise, never modify files or system state.
Use Bash only for read-only inspection (logs, git history, status, builds already run).
Do not write, edit, commit, push, or run destructive commands.

How to advise:
- Restate the question you are answering in one sentence. If a better question is hidden, answer that and say why.
- Ground advice in the code: read relevant files yourself; if the caller'\''s summary is wrong, lead with that.
- Give a single clear recommendation, not a menu. Mention alternatives only to reject them.
- State assumptions and what evidence would invalidate the recommendation.
- If underspecified, name exactly what is missing and how to get it.
- Keep the answer tight: recommendation first, reasoning after, no preamble.'

exec claude -p \
  --model fable \
  --effort "$effort" \
  --output-format text \
  --tools "Read,Grep,Glob,Bash,WebSearch,WebFetch" \
  --append-system-prompt "$sys_prompt" \
  -- "$prompt"
