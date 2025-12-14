{
  description = "SAT, the satisfiability checker";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    pre-commit.url = "github:cachix/git-hooks.nix";
    pre-commit.inputs.nixpkgs.follows = "nixpkgs";
    treefmt.url = "github:numtide/treefmt-nix";
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {

      imports = with inputs; [
        pre-commit.flakeModule
        treefmt.flakeModule
      ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem =
        {
          config,
          lib,
          pkgs,
          self',
          ...
        }:
        let
          hPkgs = pkgs.haskellPackages;
          pre-commit = config.pre-commit.settings;

          # Circumvent a bug in the interaction of Cabal and `shellFor`.
          # https://gist.github.com/ScottFreeCode/ef9f254e2dd91544bba4a068852fc81f
          # https://github.com/NixOS/nixpkgs/issues/130556#issuecomment-2762237786
          cabal-in-nix = pkgs.writeShellScriptBin "cabal" ''
            ${lib.getExe hPkgs.cabal-install} --flags=+nix "$@"
          '';

          satDevShell = hPkgs.shellFor {
            packages = _: [ self'.packages.default ];
            withHoogle = true;
            nativeBuildInputs = [
              cabal-in-nix
              hPkgs.haskell-language-server
            ];
          };
        in
        {
          packages.default = hPkgs.developPackage {
            name = "sat";
            root = ./.;
          };

          apps.default = {
            type = "app";
            program = "${self'.packages.default}/bin/sat";
            meta.description = "The SAT checker";
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [ satDevShell ] ++ lib.optional pre-commit.enable config.pre-commit.devShell;
          };

          pre-commit.settings = {
            package = pkgs.prek;
            hooks = {
              check-added-large-files.enable = true;
              check-merge-conflicts.enable = true;
              check-symlinks.enable = true;
              check-vcs-permalinks.enable = true;
              convco.enable = true;
              detect-private-keys.enable = true;
              hlint.enable = true;
              mixed-line-endings.enable = true;
              treefmt.enable = true;
              trim-trailing-whitespace.enable = true;
            };
          };

          treefmt = {
            flakeCheck = !(pre-commit.enable && pre-commit.hooks.treefmt.enable);
            programs = {
              cabal-gild.enable = true;
              fourmolu.enable = true;
              fourmolu.ghcOpts = [ "ImportQualifiedPost" ];
              nixfmt.enable = true;
            };
            settings.formatter.fourmolu.options = [ "--config=${./fourmolu.yaml}" ];
          };
        };
    };
}
