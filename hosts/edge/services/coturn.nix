{ inputs, ... }:

{
  imports = [ inputs.synix.nixosModules.coturn ];

  services.coturn = {
    enable = true;
    sops = true;
    openFirewall = true;
  };
}
