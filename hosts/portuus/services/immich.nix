{ outputs, config, lib, constants, ... }:

let
  c = constants;
  s = c.services.immich;
in
{
  imports = [ outputs.nixosModules.immich ];

  services.immich = {
    enable = true;
    reverseProxy = {
      enable = true;
      subdomain = s.subdomain;
      forceSSL = false; # TLS terminated on edge
    };
    settings.server.externalDomain = lib.mkForce "https://${s.fqdn}";
    mediaLocation = "/data/immich";
    accelerationDevices = null; # all devices
  };
}
