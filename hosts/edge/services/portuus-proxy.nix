# All public HTTP traffic enters via edge and is proxied over the Tailnet
# to portuus's internal nginx (port 80, no TLS).
# TLS is terminated on edge only.
{ lib, constants, ... }:

let
  c = constants;
  portuusIP = c.hosts.portuus.ip;
  s = c.services;

  mkProxy =
    subdomain:
    {
      extraConfig ? "",
    }:
    {
      "${subdomain}.${c.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${portuusIP}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            ${extraConfig}
          '';
        };
      };
    };
in
{
  services.nginx.virtualHosts = lib.mkMerge [
    (mkProxy s.gitlab.subdomain {
      extraConfig = "client_max_body_size 0;";
    })

    (mkProxy s.gitlab-pages.subdomain { })

    (mkProxy s.nextcloud.subdomain {
      extraConfig = ''
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Robots-Tag "noindex,nofollow" always;
        add_header X-Permitted-Cross-Domain-Policies "none" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
      '';
    })

    (mkProxy s.immich.subdomain {
      extraConfig = "client_max_body_size 5G;";
    })

    (mkProxy s.vaultwarden.subdomain { })

    (mkProxy s.radicale.subdomain { })

    (mkProxy s.jirafeau.subdomain { })

    # Matrix Synapse + Maubot (on root domain) — needs WebSocket support
    {
      "${c.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/_matrix" = {
          proxyPass = "http://${portuusIP}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        locations."/_synapse" = {
          proxyPass = "http://${portuusIP}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        locations."^~ /_matrix/maubot/" = {
          proxyPass = "http://${portuusIP}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
          '';
        };
        locations."= /.well-known/matrix/server".extraConfig = ''
          default_type application/json;
          return 200 '{"m.server":"${c.domain}:443"}';
        '';
        locations."= /.well-known/matrix/client".extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin "*";
          return 200 '{"m.homeserver":{"base_url":"https://${c.domain}"}}';
        '';
      };
    }
  ];
}
