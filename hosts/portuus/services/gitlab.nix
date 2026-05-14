{
  outputs,
  config,
  constants,
  lib,
  ...
}:

let
  c = constants;
  gl = c.services.gitlab;
  pages = c.services.gitlab-pages;
in
{
  imports = [ outputs.nixosModules.gitlab ];

  services.gitlab = {
    enable = true;
    statePath = "/data/gitlab";
    reverseProxy = {
      enable = true;
      subdomain = gl.subdomain;
      forceSSL = false; # TLS terminated on edge
    };
    # GitLab needs to know it's behind HTTPS even though local nginx is HTTP
    https = true;
    port = 443;
    mailIntegration = {
      enable = true;
      smtpHost = config.mailserver.fqdn;
    };

    pages = {
      enable = true;
      settings = {
        pages-domain = pages.fqdn;
        listen-proxy = [ "127.0.0.1:${builtins.toString pages.port}" ];
        listen-http = [ ];
        listen-https = [ ];
        gitlab-server = "https://${gl.fqdn}";
      };
    };
    extraConfig = {
      gitlab = {
        pages_enabled = true;
        pages_external_url = "https://${pages.fqdn}";
      };
      gitlab_rails = {
        trusted_proxies = [
          c.hosts.edge.ip
          c.hosts.portuus.ip
          "127.0.0.1"
        ];
      };
    };
  };


  services.nginx.virtualHosts."${pages.fqdn}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${builtins.toString pages.port}";
      proxyWebsockets = true;
    };
  };
}
