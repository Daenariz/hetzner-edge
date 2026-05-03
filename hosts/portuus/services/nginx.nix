{ inputs, constants, ... }:

let
  c = constants;
in
{
  imports = [ inputs.synix.nixosModules.nginx ];

  services.nginx = {
    enable = true;
    forceSSL = false;
    openFirewall = false; # only reachable via Tailnet
    defaultListen = [
      { addr = c.hosts.portuus.ip; port = 80; }
    ];
  };
}
