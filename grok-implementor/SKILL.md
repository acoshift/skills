---
name: grok-implementor
description: >
  Delegate well-specified code implementation to Grok CLI (grok-4.5) running
  headlessly. Grok writes the code; you (Claude) remain the architect and
  reviewer — you spec the task, Grok implements it, you verify the diff.
  Use for routine, clearly-scoped implementation work you want offloaded,
  or when the user asks to "use grok", "let grok implement", "delegate to
  grok", or runs /grok-implementor.
---

# Grok Implementor (Grok CLI delegate)

Call **Grok CLI** headlessly to **implement code** in the current repo. You (Claude) stay in charge: write a precise brief, let Grok do the edits, then review and verify the result yourself before reporting to the user.

## When to use

- Well-specified features, refactors, boilerplate, or test-writing where the approach is already decided
- Mechanical multi-file changes that follow an existing pattern
- User explicitly asks: `/grok-implementor`, "use grok for this", "delegate to grok", "let grok write it"

## When **not** to use

- The approach is still unclear — decide the design first (or ask the user); never delegate an ambiguous spec
- Tiny edits (one-liners, renames) — faster to do yourself
- Architecturally tricky, security-sensitive, or race-prone code — implement that yourself
- Anything requiring context only you have (conversation history Grok can't see) unless you put it in the brief

## Model

Always use `--model grok-4.5`. Do not substitute other models.

## How to call

From the **current project directory** (so Grok edits the right repo):

```bash
grok -p "$(cat <<'PROMPT'
# Implementation task (from Claude)

## Goal
<1-3 sentence statement of what to build/change>

## Files to touch
- path/to/file.go — what changes here

## Approach
<the decided approach — be prescriptive; Grok implements, it does not redesign>

## Constraints
- Match existing code style and idioms in the touched files
- Do not touch files outside the listed scope unless strictly required
- <project-specific constraints: Go version, no new deps, etc.>

## Done when
- <verifiable success criteria: compiles, tests X pass, behavior Y observable>
PROMPT
)" \
  --model grok-4.5 \
  --permission-mode acceptEdits \
  --check \
  --output-format plain
```

### Helper script (preferred)

If present, use the wrapper (same behavior, less prompt drift):

```bash
~/.claude/skills/grok-implementor/scripts/implement.sh <<'PROMPT'
# Implementation task (from Claude)
...
PROMPT
```

Reads the brief from stdin, or from a file with `-f brief.md`. Always runs `grok-4.5`.

### Notes

- Requires `grok` on `PATH` and auth already working (`grok login` or `XAI_API_KEY`).
- `--permission-mode acceptEdits` lets Grok edit files but not run arbitrary commands unattended. If the task needs Grok to run builds/tests itself, use `--permission-mode auto`; never use `bypassPermissions` unless the user explicitly asks.
- `--check` appends a self-verification loop — keep it on for anything non-trivial.
- For risky or large changes, add `--worktree` to isolate Grok in a git worktree, then review and merge the branch yourself.
- Timeout: implementation runs can take minutes. Use a long shell timeout (10–15 min) and run in the background for big tasks.
- If `grok` fails (not installed, auth, model unavailable), report the error to the user and implement it yourself.

## Writing the brief

The brief is the contract — Grok has none of your conversation context. Include:

1. **Goal** — one to three sentences, outcome-focused.
2. **Files to touch** — exact paths and what changes in each; Grok should not have to hunt.
3. **Approach** — the design decisions, already made. Prescriptive, not open-ended.
4. **Constraints** — style, dependencies, scope boundaries, things it must not do.
5. **Done when** — verifiable criteria (build passes, specific tests green, behavior observable).

If you can't fill in "Approach" and "Done when" concretely, the task is not ready to delegate.

## After Grok finishes

1. **Review the diff yourself** (`git diff` / `git status`) — you own the result, not Grok.
2. **Verify** the "Done when" criteria actually hold (run the build/tests; don't trust Grok's claim).
3. Fix small issues directly; re-delegate with a corrected brief only if the miss is large.
4. Summarize to the user what was implemented, what you verified, and anything you corrected. Do not present Grok's output unreviewed.
