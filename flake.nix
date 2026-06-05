{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-old-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    synix.url = "git+https://git.sid.ovh/sid/synix.git?ref=release-26.05";
    synix.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
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

      systems = [
        "x86_64-linux"
      ];

      lib = nixpkgs.lib.extend (_final: _prev: inputs.synix.lib or { });

      inherit (lib.helpers) mkPkgs;

      forAllSystems =
        function:
        lib.genAttrs systems (
          system:
          function (mkPkgs {
            inherit system;
          })
        );

      mkNixosConfiguration =
        system: modules:
        nixpkgs.lib.nixosSystem {
          inherit system modules;
          specialArgs = {
            inherit
              inputs
              outputs
              constants
              lib
              ;
          };
        };

      mkNode = name: ip: system: {
        hostname = ip;
        profiles.system = {
          path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${name};
        };
      };
    in
    {
      packages = forAllSystems (pkgs: import ./pkgs { inherit pkgs; });

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
          portuus = mkNode "portuus" constants.hosts.portuus.ip "x86_64-linux";
          edge = mkNode "edge" constants.hosts.edge.ip "x86_64-linux";
        };
      };

      checks = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
        in
        inputs.deploy-rs.lib.${system}.deployChecks self.deploy
        // {
          inherit (inputs.synix.checks.${system}) pre-commit-check;
        }
      );

      inherit (inputs.synix) formatter;
    };
}
