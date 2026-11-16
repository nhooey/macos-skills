# The skill source's upstream owner, imported by this repo's flake.nix as
# the `source` argument so agent-skill-flake namespaces package keys as
# `agent-skill-<owner>-<name>`. A flake can't read its own
# `github:owner/repo` off `self`, so the owner is stated rather than
# derived.
{ owner = "nhooey"; }
