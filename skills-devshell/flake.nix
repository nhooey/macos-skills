{
  description = "macos-skills dev-shell skill set — an isolated sub-flake invoked at RUNTIME by the root devShell, never a root input. The skill sources live only in THIS flake's lock, so the root macos-skills stays a leaf with zero skill inputs and transitive consumers never drag the skill mesh in.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    # The builder lib. agent-skill-flake carries zero skill inputs, so it does
    # not drag the skill mesh into this sub-flake's lock — only the skill
    # source below does.
    agent-skill-flake = {
      url = "github:nhooey/agent-skill-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # skillspkgs' per-family combinations, surfaced through its own subdir
    # flake. It follows the parent `nixpkgs` but NOT `agent-skill-flake`, so
    # its sources keep their own (compatible) builder; `mkDevshellSkillsFlake`
    # still runs from this flake's `agent-skill-flake.lib`.
    skillspkgs-combinations = {
      url = "github:nhooey/skillspkgs?dir=sources/combinations";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # One `mkDevshellSkillsFlake` call: the dev shell's whole skill set as a
  # single combination, surfaced as runnable apps (reconcile / purge / …).
  outputs =
    {
      nixpkgs,
      agent-skill-flake,
      ...
    }@inputs:
    agent-skill-flake.lib.mkDevshellSkillsFlake {
      inherit nixpkgs;
      systems = import inputs.systems;
      name = "macos-skills-devshell";
      # envName and packagePrefix are left at their library defaults:
      # mkDevshellSkillsFlake derives envName = "agent-skills-${name}"
      # (== agent-skills-macos-skills-devshell) and packagePrefix
      # defaults to "agent-skill-".
      sources = [
        # The skill-collections family's combination: the base set plus
        # skill authoring. No additions: this repository's scripts are shell,
        # which the base set already covers.
        { source = inputs.skillspkgs-combinations.combinations.skill-collections; }
      ];
    };
}
