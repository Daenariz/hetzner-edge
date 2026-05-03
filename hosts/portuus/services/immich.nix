{ outputs, ... }:

{
  imports = [ outputs.nixosModules.immich ];

  services.immich = {
    enable = true;
    reverseProxy = {
      enable = true;
      subdomain = "gallery";
    };
    mediaLocation = "/data/immich";
    accelerationDevices = null; # all devices
  };
}
