{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-old-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    synix.url = "git+https://git.sid.ovh/sid/synix.git?ref=release-25.11";
    synix.inputs.nixpkgs.follows = "nixpkgs";


    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";

    headplane.url = "github:tale/headplane";
    headplane.inputs.nixpkgs.follows = "nixpkgs";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    mcp-nixos.url = "github:utensils/mcp-nixos";
    mcp-nixos.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      constants = import ./constants.nix;

      supportedSystems = [
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      overlays = [ inputs.synix.overlays.default ];

      mkNixosConfiguration =
        system: modules:
        nixpkgs.lib.nixosSystem {
          inherit system modules;
          specialArgs = {
            inherit inputs outputs constants;
            lib =
              (import nixpkgs {
                inherit system overlays;
              }).lib;
          };
        };
    in
    {
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

      overlays = import ./overlays { inherit inputs; };

      nixosModules = import ./modules/nixos;

      nixosConfigurations = {
        edge = mkNixosConfiguration "x86_64-linux" [ ./hosts/edge ];
        portuus = mkNixosConfiguration "x86_64-linux" [ ./hosts/portuus ];
      };

      deploy = {
        sshUser = "root";
        user = "root";
        sshOpts = [
          "-F"
          "./ssh_config"
          "-p"
          "2299"
          "-o"
          "StrictHostKeyChecking=no"
          "-o"
          "UserKnownHostsFile=/dev/null"
        ];
        autoRollback = true;
        magicRollback = true;
        nodes = {
          portuus = {
            hostname = constants.hosts.portuus.ip;
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.portuus;
            };
          };
          edge = {
            hostname = constants.hosts.edge.ip;
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.edge;
            };
          };
        };
      };

      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          config = self.checks.${system}.pre-commit-check.config;
          inherit (config) package configFile;
          script = ''
            ${pkgs.lib.getExe package} run --all-files --config ${configFile}
          '';
        in
        pkgs.writeShellScriptBin "pre-commit-run" script
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          flakePkgs = self.packages.${system};
          overlaidPkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.modifications ];
          };
          deployChecks = inputs.deploy-rs.lib.${system}.deployChecks self.deploy;
        in
        deployChecks
        // {
          pre-commit-check = inputs.git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt.enable = true;
            };
          };
          build-packages = pkgs.linkFarm "flake-packages-${system}" flakePkgs;
          build-overlays = pkgs.linkFarm "flake-overlays-${system}" {
            # package = overlaidPkgs.package;
          };
        }
      );
    };
}
