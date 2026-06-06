{ inputs, constants, ... }:

let
  c = constants;
  s = c.services.radicale;
in
{
  imports = [ inputs.synix.nixosModules.radicale ];

  services.radicale = {
    enable = true;
    reverseProxy = {
      enable = true;
      inherit (s) subdomain;
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
