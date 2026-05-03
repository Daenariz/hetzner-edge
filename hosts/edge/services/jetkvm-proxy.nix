{ ... }:

let
  c = import ../../../constants.nix;
in
{
  services.nginx = {
    appendHttpConfig = ''
      map $http_upgrade $connection_upgrade {
        default upgrade;
        ""      close;
      }
    '';

    virtualHosts."jetkvm-proxy" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = 8080;
        }
      ];

      locations."/" = {
        proxyPass = "http://${c.hosts.jetkvm.ip}:80";
        proxyWebsockets = false; # see below

        extraConfig = ''
          proxy_http_version 1.1;

          proxy_set_header Host ${c.hosts.jetkvm.ip};
          proxy_set_header Origin http://${c.hosts.jetkvm.ip};

          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection $connection_upgrade;

          proxy_buffering off;
        '';
      };
    };
  };
}
