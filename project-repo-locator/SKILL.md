---
name: project-repo-locator
description: Tells Claude Code where the user's other local repositories live, so cross-repository lookups go straight to the right place instead of searching the whole filesystem. Use this whenever a task requires looking at source code that is NOT in the current working repository — for example when the user references another repo by name ("how does auth-service do X", "check the arpc library"), asks how something is implemented in a dependency or sibling project, or wants to compare code across repos. Trigger this even when the user doesn't explicitly say "repo" or give a path, as long as they're pointing at code that lives outside the current project.
---

# Project Repo Locator

The user keeps their local repositories under `~/Projects`, organized by org:

```
~/Projects/<org>/<repo>
```

For example: `~/Projects/acoshift/arpc`, `~/Projects/myco/auth-service`.

This skill exists for one reason: when a task needs source code that is **not in the current working repository**, look there — not at the home directory, not at `/`, not wherever a global search happens to wander. A filesystem-wide search is slow, noisy, and can match unrelated copies (vendored code, backups, `node_modules`). Going straight to `~/Projects/<org>/<repo>` is fast and unambiguous.

This skill only tells you *where* to look. What to do once you've found the repo — read a file, grep for a symbol, check git history, compare implementations — is your call, based on the task.

## When this applies

Use this whenever the code you need lives outside the current repo. Common signals:

- The user names another repository or project ("how does `auth-service` handle sessions?").
- The user asks how something works in a dependency or library that they also develop locally ("check how `arpc` defines its error type").
- The user wants to compare or reuse code across repositories ("do it the same way we did in `billing-api`").

If the code is in the current working repository, you don't need this skill — just search the current repo normally.

## How to locate a repo

You need an org and a repo name to build the path `~/Projects/<org>/<repo>`. The user usually gives the repo name but not the org. Resolve the org in this order:

1. **Infer the org from the current working directory.** If the current repo is itself under `~/Projects/<org>/...`, that `<org>` is the most likely home for the repo you're looking for — people keep related projects together under the same org. So check there first:

   ```bash
   test -d ~/Projects/<org>/<repo> && echo found
   ```

   This is the fastest path and resolves the common case (a sibling repo) with a single check.

2. **Use org context from the conversation.** If you're not in a `~/Projects` repo, or step 1 didn't match, check whether the user or earlier conversation already named the org.

3. **Fall back to a name search across orgs.** If the org is still unknown, list the org directories and look for a matching repo — still bounded and cheap, since it only globs one level under `~/Projects`:

   ```bash
   ls -d ~/Projects/*/<repo> 2>/dev/null
   ```

Once you have a path, **confirm it exists** before working with it. Then proceed with whatever the task needs.

## When the repo isn't there

If the repo isn't found under `~/Projects`, **stop and tell the user.** Do not fall back to searching the rest of the filesystem — that's exactly the behavior this skill is meant to prevent.

Tell them what you looked for and where, and ask how to proceed. For example: "I didn't find `auth-service` under `~/Projects` (checked each org directory). Is it cloned locally, or under a different name?"

If you found the repo name under an unexpected org, or found multiple matches, surface that to the user rather than guessing which one they meant.
