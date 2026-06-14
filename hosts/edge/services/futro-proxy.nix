# All public HTTP traffic enters via edge and is proxied over the Tailnet
# to futro's internal nginx (port 80, no TLS).
# TLS is terminated on edge only.
{ lib, constants, ... }:

let
  c = constants;
  futroIP = c.hosts.futro.ip;
  s = c.services;

  mkProxy = subdomain: extraConfig: {
    "${subdomain}.${c.domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${futroIP}";
        inherit extraConfig;
      };
    };
  };
in
{
  services.nginx.virtualHosts = lib.mkMerge [
    # (mkProxy s.forgejo.subdomain "client_max_body_size 0;")
    # (mkProxy s.gitlab-pages.subdomain "")
    # (mkProxy s.nextcloud.subdomain "client_max_body_size 1G;")
    # (mkProxy s.immich.subdomain "client_max_body_size 5G;")
    (mkProxy s.vaultwarden.subdomain "")
    (mkProxy s.radicale.subdomain "")
    # (mkProxy s.jirafeau.subdomain "")

    # Matrix Synapse + Maubot (on root domain)
    {
      "${c.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations = {
          "/_matrix".proxyPass = "http://${futroIP}";
          "/_synapse".proxyPass = "http://${futroIP}";
          "^~ /_matrix/maubot/" = {
            proxyPass = "http://${futroIP}";
            proxyWebsockets = true;
          };
          "= /.well-known/matrix/server".extraConfig = ''
            default_type application/json;
            return 200 '{"m.server":"${c.domain}:443"}';
          '';
          "= /.well-known/matrix/client".extraConfig = ''
            default_type application/json;
            add_header Access-Control-Allow-Origin "*";
            return 200 '{"m.homeserver":{"base_url":"https://${c.domain}"}}';
          '';
        };
      };
    }
  ];
}
