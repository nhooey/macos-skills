# macos-skills

Coding-agent skills for macOS, packaged as a Nix flake.

Each skill is a self-contained directory under [`skills/`](skills/) with a
`SKILL.md` (frontmatter + instructions) that an agent loads on demand. The flake
builds every skill into an installable package and exposes apps that reconcile
an agent's skill directory to exactly the set this flake declares. Skills are
built by [`agent-skill-flake`](https://github.com/nhooey/agent-skill-flake).

## Skills

| Skill                                                                  | What it does                                                                                                                                                                        |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`macos-spotlight-repair`](skills/macos-spotlight-repair/SKILL.md)     | Finds why Spotlight misses an app and repairs the Data volume's index mildest step first: restart `mds`, re-import, rebuild. Ships `scripts/spotlight-repair`.                      |
| [`macos-unified-log-triage`](skills/macos-unified-log-triage/SKILL.md) | Reads the unified log, crash reports and launchd jobs for real problems: `/usr/bin/log`, not zsh's `log` builtin, empty results proved, counts by process, routine noise set aside. |

## Install

Each skill is an output package, plus an aggregate `default` that bundles them all.

```bash
# Preview what installing every skill would change, without writing anything
nix run github:nhooey/macos-skills#preview

# Install all skills into the agent's skill directory
nix run github:nhooey/macos-skills#install

# Converge the skill directory to exactly this flake's declared set
nix run github:nhooey/macos-skills#reconcile

# Remove the skills this flake installed
nix run github:nhooey/macos-skills#uninstall
```

Package outputs:

- `agent-skills-nhooey-macos-all`: the aggregate of every skill (also `default`)
- `agent-skill-nhooey-macos-spotlight-repair`
- `agent-skill-nhooey-macos-unified-log-triage`

## Development

```bash
nix develop      # enter the dev shell; run `menu` to list commands
nix fmt          # nixfmt over *.nix, prettier over *.md / *.yaml
nix flake check  # the treefmt check, plus shellcheck and the bats suites in tests/
```
