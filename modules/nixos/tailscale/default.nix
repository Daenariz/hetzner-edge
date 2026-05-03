{ inputs, pkgs, ... }:

{
  imports = [ inputs.synix.nixosModules.tailscale ];

  services.tailscale = {
    enable = true;
    tailnets.portuus = {
      loginServer = "https://hs.portuus.de";
      enableSSH = true;
      default = true;
    };
  };

  environment.systemPackages = with pkgs; [
    kitty # to be able to copy term info
  ];
}
