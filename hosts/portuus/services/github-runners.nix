{
  outputs,
  config,
  pkgs,
  ...
}:

{
  imports = [ outputs.nixosModules.github-runner ];

  services.github-runners.portuus = {
    enable = true;
    url = "https://github.com/stherm/portuus";
    tokenFile = config.sops.secrets."github-runners/portuus/token".path;

    extraPackages = with pkgs; [
      deploy-rs
      git
      nix
      openssh
      gzip
    ];

    extraEnvironment.DEPLOY_KEY_PATH = config.sops.secrets."github-runners/portuus/deploy-key".path;
  };

  users.users.portuus.extraGroups = [ "kvm" ];

  sops.secrets =
    let
      owner = "portuus";
      group = "portuus";
      mode = "0600";
    in
    {
      "github-runners/portuus/token" = { inherit owner group mode; };
      "github-runners/portuus/deploy-key" = { inherit owner group mode; };
    };
}
