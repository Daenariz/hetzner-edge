{ config, pkgs, ... }:

let
  user = "github-runner-portuus";
  tokenFile = config.sops.secrets."github-runners/portuus/token".path;
  deployKeyFile = config.sops.secrets."github-runners/portuus/deploy-key".path;
  home = "/var/lib/github-runner/portuus";
in
{
  nix.settings.trusted-users = [ user ];

  services.github-runners = {
    portuus = {
      enable = true;
      url = "https://github.com/stherm/portuus";
      inherit user;
      group = user;
      inherit tokenFile;

      extraPackages = with pkgs; [
        deploy-rs
        git
        nix
        openssh
        gzip
      ];

      extraEnvironment = {
        DEPLOY_KEY_PATH = deployKeyFile;
      };
    };
  };

  users.groups.${user} = { };
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    extraGroups = [ "kvm" ];
    description = "Github Runner for Portuus";
    inherit home;
    createHome = true;
  };

  sops =
    let
      owner = user;
      group = user;
      mode = "0600";
    in
    {
      secrets."github-runners/portuus/token" = { inherit owner group mode; };
      secrets."github-runners/portuus/deploy-key" = { inherit owner group mode; };
    };
}
