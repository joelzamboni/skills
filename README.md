# skills

Open-source [Claude Code](https://code.claude.com) skills, packaged as
installable plugins. This repo is also a plugin marketplace — you can install
everything with two commands.

## Install as a plugin (recommended)

In Claude Code:

```
/plugin marketplace add joelzamboni/skills
/plugin install example@zamboni-skills
```

Plugins installed this way pick up updates when the marketplace refreshes.

## Install a single skill manually

Copy any skill folder into your personal skills directory:

```bash
git clone https://github.com/joelzamboni/skills
cp -r skills/plugins/example/skills/hello ~/.claude/skills/
```

Or into a project's `.claude/skills/` to share it with your team via that
project's repo.

## What's inside

| Plugin | Contents | Description |
| ------ | -------- | ----------- |
| `example` | `hello` skill | Starter example — replace with real skills |
| `github-issue-reminder` | Stop hook | Reminds the agent to update the GitHub issue after changing files |

## Repo layout

```
.claude-plugin/marketplace.json   # marketplace catalog
plugins/<plugin>/
  .claude-plugin/plugin.json      # plugin manifest
  skills/<skill>/SKILL.md         # one folder per skill
```

To add a skill: create `plugins/<plugin>/skills/<name>/SKILL.md`. To add a
plugin: create the folder above and list it in
`.claude-plugin/marketplace.json`. Validate before publishing:

```bash
claude plugin validate ./plugins/<plugin>
```

## License

[MIT](LICENSE)
