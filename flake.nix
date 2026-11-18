{
  description = "macos-skills: Coding-agent skills for macOS as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # Declared explicitly even though `agent-skill-flake` already pulls in
    # `treefmt-nix` transitively: this flake owns its formatter toolchain. The
    # input below `follows` it so the whole tree resolves to one version.
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The builder library, not a skill: it turns skill directories into
    # installable flakes, aggregates them, and exports the
    # `flakeModules.devshellSkills` module for the dev shell. It carries no
    # skill inputs; the dev shell's skills live in the `skills-devshell/`
    # sub-flake and are invoked at runtime.
    agent-skill-flake = {
      url = "github:nhooey/agent-skill-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };

  outputs =
    {
      nixpkgs,
      flake-parts,
      agent-skill-flake,
      ...
    }@inputs:
    let
      # Every skill under ./skills as a package, plus the aggregate and the
      # install/preview apps.
      base = agent-skill-flake.lib.mkAllSkillsFlake {
        inherit nixpkgs;
        source = import ./source.nix;
        skillsDir = ./skills;
        packagePrefix = "agent-skill-";
        # Ship the reference pages a SKILL.md links beside it. Lower-case
        # names only, so a skill's README.md stays in the repo.
        extraFiles = [ "[a-z]*.md" ];
        # Owner+topic, so the aggregate's key can't collide with other repos
        # merged into skillspkgs / nur-packages.
        name = "agent-skills-nhooey-macos-all";
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.agent-skill-flake.flakeModules.devshellSkills
        inputs.treefmt-nix.flakeModule
      ];

      agent-skill-flake.devshellSkills = {
        name = "macos-skills";
        motd = ''
          {bold}{14}🚀 Entering macos-skills dev shell{reset}
          Run {bold}menu{reset} to list available commands.
        '';
      };
      perSystem =
        { pkgs, system, ... }:
        let
          # This repository's lint and test commands (scripts/macos-skills),
          # with shellcheck, bats and yq (which the description tests parse
          # the skills' frontmatter with) on its PATH. The dev shell's menu
          # and `checks.scripts` both run it, so they lint and test the same
          # way.
          macos-skills = pkgs.writeShellApplication {
            name = "macos-skills";
            runtimeInputs = [
              pkgs.bats
              pkgs.git
              pkgs.shellcheck
              pkgs.yq-go
            ];
            text = builtins.readFile ./scripts/macos-skills;
          };
        in
        {
          packages = base.packages.${system};

          apps = base.apps.${system};

          devshells.default.commands = [
            {
              category = "dev";
              package = macos-skills;
              help = "Lint the skills' scripts with shellcheck and run the bats suites (lint | test | all)";
            }
          ];

          # The skills' scripts and scripts/: shellcheck, and the bats suites
          # under tests/, which stub the macOS commands so they run on any
          # system.
          checks.scripts =
            pkgs.runCommand "macos-skills-scripts"
              {
                nativeBuildInputs = [ macos-skills ];
              }
              ''
                cp -r ${./skills} skills
                cp -r ${./scripts} scripts
                cp -r ${./tests} tests
                chmod -R u+w .
                patchShebangs skills scripts tests
                macos-skills --root . all
                touch $out
              '';

          # `nix fmt` runs nixfmt over `.nix` and prettier over `.md` / `.yaml`;
          # `nix flake check` fails on any unformatted file.
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.prettier.enable = true;
            settings.formatter.prettier.includes = [
              "*.md"
              "*.yaml"
              "*.yml"
            ];
          };
        };
    };
}
