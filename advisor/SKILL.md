---
name: advisor
description: >
  Consult Claude CLI (Fable model, effort high or xhigh) as a senior technical
  advisor for hard architectural decisions, design trade-offs, gnarly debugging
  hypotheses, plan reviews, or any problem where a stronger second opinion is
  worth the cost. Consultation only — never edits files. Use when Grok is stuck
  on a hard problem, needs an advisor consult, second opinion, architecture
  review, or the user runs /advisor.
---

# Advisor (Claude Fable consult)

Call **Claude Code CLI** with **Fable** at high effort for a **read-only** second opinion. You (Grok) remain the implementer; the advisor only advises.

## When to use

- Hard architecture / design trade-offs
- Gnarly debugging where hypotheses disagree
- Reviewing a plan before a large or risky change
- User asks for `/advisor`, "consult fable", "second opinion", "ask the advisor"

## When **not** to use

- Routine questions you can answer confidently
- Simple refactors, typos, or lookups
- When the user only needs a quick fact
- Prefer **not** to spam this: each call is expensive

## Effort

| Situation | Flag |
|-----------|------|
| Default hard problem | `--effort xhigh` |
| Faster / cheaper consult (still hard, not critical) | `--effort high` |
| User says "max" / "ultrathink" | `--effort max` if available, else `xhigh` |

Default to **xhigh** unless the user asks for high or the problem is mid-weight.

## How to call

From the **current project directory** (so Claude can read the repo):

```bash
claude -p \
  --model fable \
  --effort xhigh \
  --output-format text \
  --tools "Read,Grep,Glob,Bash,WebSearch,WebFetch" \
  --append-system-prompt "$(cat <<'SYS'
You are a senior technical advisor consulted by Grok (another coding agent).
Consultation only: advise, never modify files or system state.
Use Bash only for read-only inspection (logs, git history, status, builds already run).
Do not write, edit, commit, push, or run destructive commands.

How to advise:
- Restate the question you are answering in one sentence. If a better question is hidden, answer that and say why.
- Ground advice in the code: read relevant files yourself; if the caller's summary is wrong, lead with that.
- Give a single clear recommendation, not a menu. Mention alternatives only to reject them.
- State assumptions and what evidence would invalidate the recommendation.
- If underspecified, name exactly what is missing and how to get it.
- Keep the answer tight: recommendation first, reasoning after, no preamble.
SYS
)" \
  -- "$(cat <<'PROMPT'
# Advisor consult (from Grok)

## Problem
<1-3 sentence problem statement>

## What I already tried / believe
- ...

## Relevant paths / symbols
- path/to/file.go — why it matters

## Question for you
<the decision or hypothesis to resolve>

## Constraints
- ...
PROMPT
)"
```

### Helper script (preferred)

If present, use the wrapper (same behavior, less prompt drift):

```bash
~/.grok/skills/advisor/scripts/consult.sh xhigh <<'PROMPT'
# Advisor consult (from Grok)
...
PROMPT
```

First arg is effort: `high` | `xhigh` | `max` (default `xhigh`).

### Notes

- Requires `claude` on `PATH` and auth already working (`claude auth` / existing login).
- Do **not** pass `--dangerously-skip-permissions` for advisor consults.
- `--tools` is restricted to inspection tools; do not add `Edit`/`Write`.
- Timeout: Fable + xhigh can take several minutes. Use a long shell timeout (e.g. 10–15 min).
- If `claude` fails (not installed, auth, model unavailable), report the error to the user and fall back to your own best judgment.

## After the reply

1. Summarize the advisor’s **recommendation** to the user in your own words (cite key points).
2. Say whether you will follow it, adapt it, or reject it — and why.
3. Only then implement (if implementation was requested). Do not silently ignore the advisor.
