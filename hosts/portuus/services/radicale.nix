{ inputs, ... }:

let
  c = import ../../../constants.nix;
  s = c.services.radicale;
in
{
  imports = [ inputs.synix.nixosModules.radicale ];

  services.radicale = {
    enable = true;
    reverseProxy = {
      enable = true;
      subdomain = s.subdomain;
      forceSSL = false; # TLS terminated on edge
    };
    users = [
      "pascal"
      "portuus"
      "susagi"
      "steffen"
      "ulm"
    ];
  };
}
