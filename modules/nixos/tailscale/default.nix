{ inputs, pkgs, config, ... }:

{
  imports = [ inputs.synix.nixosModules.tailscale ];

  services.tailscale = {
    enable = true;
    tailnets.portuus = {
      loginServer = "https://hs.portuus.de";
      authKeyFile = config.sops.secrets."tailscale/auth-key".path;
      enableSSH = true;
      default = true;
    };
  };

  sops.secrets."tailscale/auth-key" = {};

  environment.systemPackages = with pkgs; [
    kitty # to be able to copy term info
  ];
}
