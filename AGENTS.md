# macos-skills

Coding-agent skills for macOS, packaged as a Nix flake. Each skill is a directory under `skills/` with a `SKILL.md`, built by agent-skill-flake; the bats suites for the skills' scripts live in `tests/`.

## Build and test

- `nix develop`: the dev shell, with the project's skills installed into `.agents/skills/` from the `skills-devshell/` sub-flake.
- `nix build`: builds every skill under `skills/` as a package, and the aggregate.
- `nix flake check`: runs shellcheck over the skills' scripts and the bats suites under `tests/`, and fails on any file `nix fmt` would change.
- `nix fmt`: formats the Nix files with nixfmt and the Markdown and YAML files with prettier.
