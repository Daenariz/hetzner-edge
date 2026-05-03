{ outputs, config, ... }:

let
  domain = config.networking.domain;

  subdomain = "git";
  fqdn = "${subdomain}.${domain}";

  pages.subdomain = "pages";
  pages.fqdn = "${pages.subdomain}.${domain}";
  pages.port = 8090;
  pages.aliases = [ ];
in
{
  imports = [ outputs.nixosModules.gitlab ];

  services.gitlab = {
    enable = true;
    statePath = "/data/gitlab";
    reverseProxy = {
      enable = true;
      inherit subdomain;
    };
    mailIntegration = {
      enable = true;
      smtpHost = config.mailserver.fqdn;
    };

    # TODO: set in nix-core
    pages = {
      enable = true;
      settings = {
        pages-domain = pages.fqdn;
        listen-proxy = [ "127.0.0.1:${builtins.toString pages.port}" ];
        listen-http = [ ];
        listen-https = [ ];
        gitlab-server = "https://${fqdn}";
      };
    };
    extraConfig = {
      gitlab = {
        pages_enabled = true;
        pages_external_url = "https://${pages.fqdn}";
      };
    };
  };

  services.nginx.virtualHosts."${pages.fqdn}" = {
    serverAliases = pages.aliases;
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${builtins.toString pages.port}";
      proxyWebsockets = true;
    };
  };
}
