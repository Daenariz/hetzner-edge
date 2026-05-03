{
  outputs,
  config,
  pkgs,
  ...
}:

let
  domain = config.networking.domain;

  package = pkgs.nextcloud32.overrideAttrs (old: rec {
    version = "32.0.3";
    src = pkgs.fetchurl {
      url = "https://download.nextcloud.com/server/releases/nextcloud-${version}.tar.bz2";
      hash = "sha256-m3GslskQtKNQ2Ya9OpLqBvAqFh+lhjNLVth9isr8YtQ=";
    };
  });
in
{
  imports = [ outputs.nixosModules.nextcloud ];

  services.nextcloud = {
    enable = true;
    inherit package;
    datadir = "/data/nextcloud";
    reverseProxy = {
      enable = true;
      subdomain = "cloud";
    };
    mailIntegration = {
      enable = true;
      smtpHost = config.mailserver.fqdn;
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        bookmarks
        calendar
        contacts
        richdocuments
        tasks
        # whiteboard # FIXME: https://github.com/sid115/portuus/issues/6
        ;
    };
    # NOTE: office.portuus.de is down atm
    # settings = {
    #   richdocuments = {
    #     wopi_url = "https://office.${domain}";
    #   };
    # };
  };

  services.nginx.virtualHosts."cloud.${domain}".extraConfig = ''
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Robots-Tag "noindex,nofollow" always;
    add_header X-Permitted-Cross-Domain-Policies "none" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
  '';

  # NOTE: office.portuus.de is down atm
  # TODO: add to nextcloud nix-core nixos module
  # services.collabora-online = {
  #   enable = true;
  #   port = 9980;
  #   settings = {
  #     # rely on reverse proxy for SSL
  #     ssl = {
  #       enable = false;
  #       termination = true;
  #     };
  #     storage.wopi = {
  #       "@allow" = true;
  #       host = [ "cloud.${domain}" ];
  #     };
  #     server_name = "office.${domain}";
  #   };
  # };

  # NOTE: office.portuus.de is down atm
  # services.nginx.virtualHosts."office.${domain}" = {
  #   forceSSL = true;
  #   enableACME = true;
  #   locations."/" = {
  #     proxyPass = "http://127.0.0.1:${toString config.services.collabora-online.port}";
  #     proxyWebsockets = true;
  #   };
  # };
}
