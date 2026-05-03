{ inputs, ... }:

let
  c = import ../../../constants.nix;
  s = c.services.jirafeau;
in
{
  imports = [ inputs.synix.nixosModules.jirafeau ];

  services.jirafeau = {
    enable = true;
    dataDir = "/data/jirafeau";
    reverseProxy = {
      enable = true;
      subdomain = s.subdomain;
      forceSSL = false; # TLS terminated on edge
    };
  };
}
