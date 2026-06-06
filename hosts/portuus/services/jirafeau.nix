{ inputs, constants, ... }:

let
  c = constants;
  s = c.services.jirafeau;
in
{
  imports = [ inputs.synix.nixosModules.jirafeau ];

  services.jirafeau = {
    enable = true;
    dataDir = "/data/jirafeau";
    reverseProxy = {
      enable = true;
      inherit (s) subdomain;
      forceSSL = false; # TLS terminated on edge
    };
  };
}
