{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix-shell.url = "github:aciceri/agenix-shell";
    systems.url = "github:nix-systems/default";
    devshell.url = "github:numtide/devshell";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = with inputs; [
        devshell.flakeModule
        treefmt.flakeModule
        git-hooks.flakeModule
        agenix-shell.flakeModules.default
      ];

      agenix-shell = {
        secrets = {
          DISCORD_TOKEN.file = ./secrets/Discord_Token.age;
        };
      };

      perSystem =
        {
          pkgs,
          lib,
          system,
          config,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ (import inputs.rust-overlay) ];
          };

          pre-commit = {
            settings.hooks = {
              deadnix.enable = true;
              flake-checker.enable = true;
              commitizen.enable = true;
              check-merge-conflicts.enable = true;
              #no-commit-to-branch.enable = true;
              treefmt.enable = true;
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            flakeCheck = true;
            settings.hooks = {
              nixfmt.enable = true;
              statix.enable = true;
              yamlfmt.enable = true;

              rustfmt.enable = true;
              taplo.enable = true;
            };
          };

          packages.default = pkgs.callPackage ./. { };

          devshells.default = {
            devshell.startup.pre-commit.text = config.pre-commit.installationScript;
            devshell.startup.agenix.text = ''source ${lib.getExe config.agenix-shell.installationScript}'';

            devshell.packages = with pkgs; [
              config.formatter
              (rust-bin.selectLatestNightlyWith (
                toolchain:
                toolchain.minimal.override {
                  extensions = [ "rustc-codegen-cranelift-preview" ];
                }
              ))
              bacon
            ];

            commands =
              let
                # Thanks to this, the user can choose to use `nix-output-monitor` (`nom`) instead of plain `nix`
                #nix = ''$([ "$\{NOM:-0}" = '1' ] && echo ${pkgs.lib.getExe pkgs.nix-output-monitor} || echo nix)'';
              in
              [
                {
                  name = "update-flakes";
                  help = "Updates all flakes";
                  command = ''
                                    echo "=> Updating all flakes..."
                    								export PROJECT_ROOT="${self.sourceInfo.outPath}"




                                    								nix flake update 
                                    								nix flake update --flake $PROJECT_ROOT/flake/
                                    							'';
                }
                {
                  name = "run";
                  help = "Runs the discord bot";
                  command = ''
                    										echo "=> Running the bot...."
                    										cargo run
                    									'';
                }
                {
                  name = "run-watch";
                  help = "Runs the discord bot in watch mode";
                  command = ''
                    										  echo "=> Running the bot with watch enabled...."
                    											bacon -j run --watch .
                    									'';
                }
              ];
          };
        };
    };
}
