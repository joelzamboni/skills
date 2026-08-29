# github-issue-reminder

A Stop hook that reminds the agent to update the GitHub issue or ticket
before it finishes, whenever a session changed files in a repo with a
GitHub remote.

## Behavior

- Fires only in git repos that have a GitHub remote and real work changes
  (working tree + unpushed commits, ignoring `.claude/` and `NOTES.md`).
- Blocks the stop at most **once per batch of changes**: after a reminder,
  it stays quiet until new files are touched.
- Infers the issue number from the branch name (`123-fix-foo`, `issue/123`,
  `feature/123-bar`) and names it in the reminder when it can.
- Trust-based: it asks the agent to update the issue (e.g. via
  `gh issue comment`) or briefly explain why no update is warranted — it
  does not verify the issue was actually updated.
- Never loops: respects the `stop_hook_active` guard.

## Install

```
/plugin marketplace add joelzamboni/skills
/plugin install github-issue-reminder@zamboni-skills
```
