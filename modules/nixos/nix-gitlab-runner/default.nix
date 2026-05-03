# https://nixos.wiki/wiki/Gitlab_runner

# Troubleshooting:
# Cannot connect to the Docker daemon at unix:///var/run/docker.sock
# sudo systemctl restart podman.socket gitlab.service gitlab-runner.service

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.nix-gitlab-runner;

  inherit (lib)
    concatStringsSep
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    types
    ;
in
{
  options.services.nix-gitlab-runner = {
    enable = mkEnableOption "Nix-based GitLab Runner service";
    authenticationTokenConfigFile = mkOption {
      type = types.path;
      description = "Path to the GitLab Runner registration config file containing CI_SERVER_URL and REGISTRATION_TOKEN.";
    };
    nixosChannel = mkOption {
      type = types.str;
      default = "nixos-unstable";
      description = "NixOS channel to use inside the GitLab Runner Docker containers.";
    };
    containerRuntime = lib.mkOption {
      type = types.enum [
        "docker"
        "podman"
      ];
      default = "podman";
      description = "The container runtime engine to use.";
    };
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl."net.ipv4.ip_forward" = true;
    virtualisation = {
      docker.enable = cfg.containerRuntime == "docker";
      podman = optionalAttrs (cfg.containerRuntime == "podman") {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
      };
    };
    # https://github.com/NixOS/nixpkgs/issues/151108#issuecomment-2907056090
    systemd.sockets.podman = optionalAttrs (cfg.containerRuntime == "podman") {
      socketConfig.Symlinks = [
        "/var/run/docker.sock"
      ];
    };

    services.gitlab-runner = {
      enable = true;
      services = {
        nix = {
          inherit (cfg) authenticationTokenConfigFile;
          dockerImage = "alpine";
          dockerVolumes = [
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          ];
          dockerDisableCache = true;
          preBuildScript = pkgs.writeScript "setup-container" ''
            mkdir -p -m 0755 /nix/var/log/nix/drvs
            mkdir -p -m 0755 /nix/var/nix/gcroots
            mkdir -p -m 0755 /nix/var/nix/profiles
            mkdir -p -m 0755 /nix/var/nix/temproots
            mkdir -p -m 0755 /nix/var/nix/userpool
            mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
            mkdir -p -m 1777 /nix/var/nix/profiles/per-user
            mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
            mkdir -p -m 0700 "$HOME/.nix-defexpr"
            . ${pkgs.nix}/etc/profile.d/nix-daemon.sh
            ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/${cfg.nixosChannel} nixpkgs
            ${pkgs.nix}/bin/nix-channel --update nixpkgs
            ${pkgs.nix}/bin/nix-env -i ${
              concatStringsSep " " (
                with pkgs;
                [
                  nix
                  cacert
                  git
                  openssh
                ]
              )
            }
          '';
          environmentVariables = {
            ENV = "/etc/profile";
            USER = "root";
            NIX_REMOTE = "daemon";
            PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
            NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
            NIX_CONFIG = "extra-experimental-features = nix-command flakes";
          };
          tagList = [ "nix" ];
        };
      };
    };
  };
}
