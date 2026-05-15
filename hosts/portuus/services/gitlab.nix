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
        ssh_port = gl.sshPort;
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

  # Disable recommendedProxySettings for GitLab location so we can set
  # X-Forwarded-Proto to "https" (portuus nginx $scheme is "http" since
  # TLS terminates on edge). Without this, the include overwrites our header.
  services.nginx.virtualHosts."${gl.fqdn}".locations."/" = {
    recommendedProxySettings = lib.mkForce false;
    extraConfig = lib.mkForce ''
      client_max_body_size 0;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header X-Forwarded-Ssl on;
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-Server $hostname;
      proxy_set_header Connection "";
    '';
  };

  services.nginx.virtualHosts."${pages.fqdn}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${builtins.toString pages.port}";
      proxyWebsockets = true;
    };
  };
}
