#!/usr/bin/env bash
#
# issue-reminder.sh: Stop hook for the github-issue-reminder plugin.
#
# When a session has changed files in a repo with a GitHub remote, block the
# stop and remind the agent to update the GitHub issue or ticket for the work.
# Fires at most once per batch of changes: the marker file stores a hash of
# the touched-file set, so a reminder re-arms only when new work appears
# after it. Never loops (stop_hook_active guard).

set -u

INPUT="$(cat)"

# stop_hook_active guard: never block a stop we already blocked
case "$INPUT" in
    *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

if command -v jq >/dev/null 2>&1; then
    SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo unknown)"
else
    SESSION_ID="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
    SESSION_ID="${SESSION_ID:-unknown}"
fi

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# A reminder to update a GitHub issue only makes sense with a GitHub remote
git remote -v 2>/dev/null | grep -qiE 'github' || exit 0

# Paths touched: working tree changes + commits not yet pushed
TOUCHED="$( { git status --porcelain 2>/dev/null | cut -c4- | sed 's/.* -> //'; \
              git log @{u}..HEAD --name-only --pretty=format: 2>/dev/null; } | sed '/^$/d' | sort -u )"
[ -z "$TOUCHED" ] && exit 0

WORK_TOUCHED="$(printf '%s\n' "$TOUCHED" | grep -v -E '^(\.claude/|NOTES\.md$)' || true)"
[ -z "$WORK_TOUCHED" ] && exit 0

# One reminder per batch of work: the marker stores a hash of the touched
# set, so the reminder re-arms when new changes appear after it fired.
HASH="$(printf '%s\n' "$WORK_TOUCHED" | cksum | tr -d ' \t')"
MARKER="${TMPDIR:-/tmp}/gh-issue-reminder-$(printf '%s' "$SESSION_ID" | tr -cd 'a-zA-Z0-9-')"
[ -e "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$HASH" ] && exit 0
printf '%s' "$HASH" > "$MARKER"

# Infer the issue number from the branch name (123-fix-foo, issue/123,
# feature/123-bar). Sanitize the branch before embedding it in JSON.
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -cd 'a-zA-Z0-9._/-')"
ISSUE="$(printf '%s' "$BRANCH" | grep -oE '(^|[/#-])[0-9]+' | grep -oE '[0-9]+' | head -1 || true)"

if [ -n "$ISSUE" ]; then
    HINT="The branch name ($BRANCH) suggests this is issue #$ISSUE."
else
    HINT="No issue number could be inferred from the branch name ($BRANCH); work out which issue this belongs to from context, or ask the user rather than guess."
fi

REASON="This session changed files in a repo with a GitHub remote, but the tracking issue has not been confirmed as updated. $HINT Update the GitHub issue for this work — for example with: gh issue comment <number> --body <note>. Write it as an operational record rather than a code summary: what changed, the commands actually run, the state things are in now, and what is still open. If the change genuinely does not warrant an issue update (a typo, a scratch file), say so briefly to the user and finish. This reminder fires once per batch of changes."

if command -v jq >/dev/null 2>&1; then
    jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
else
    # REASON and HINT are built without double quotes or backslashes, so
    # embedding them directly is JSON-safe.
    printf '{"decision": "block", "reason": "%s"}\n' "$REASON"
fi

exit 0
