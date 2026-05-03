{ inputs, ... }:

{
  imports = [ inputs.synix.nixosModules.jirafeau ];

  services.jirafeau = {
    enable = true;
    dataDir = "/data/jirafeau";
    reverseProxy = {
      enable = true;
      subdomain = "share";
    };
  };
}
