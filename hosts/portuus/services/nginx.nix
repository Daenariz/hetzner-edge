{ inputs, ... }:

{
  imports = [ inputs.synix.nixosModules.nginx ];

  services.nginx = {
    enable = true;
    forceSSL = true;
    openFirewall = true;
  };
}
