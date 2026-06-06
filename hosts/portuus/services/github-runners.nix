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
    user = "github-runner-portuus";
    group = "github-runner-portuus";
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

  users.users.github-runner-portuus.extraGroups = [ "kvm" ];

  sops.secrets =
    let
      owner = "github-runner-portuus";
      group = "github-runner-portuus";
      mode = "0600";
    in
    {
      "github-runners/portuus/token" = { inherit owner group mode; };
      "github-runners/portuus/deploy-key" = { inherit owner group mode; };
    };
}
