{
  outputs,
  ...
}:

{
  imports = [
    ./github-runners.nix
    ./gitlab-runner.nix
    ./gitlab.nix
    ./immich.nix
    ./jirafeau.nix
    ./mailserver.nix
    ./matrix-synapse.nix
    ./minecraft-servers.nix
    ./nextcloud.nix
    ./nginx.nix
    ./openssh.nix
    ./radicale.nix
    ./rustdesk-server.nix
    ./vaultwarden.nix
    ./zfs.nix

    outputs.nixosModules.tailscale
  ];
}
