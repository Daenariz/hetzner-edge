{
  outputs,
  config,
  pkgs,
  lib,
  constants,
  ...
}:

let
  c = constants;
  s = c.services.nextcloud;

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
      inherit (s) subdomain;
      forceSSL = false; # TLS terminated on edge
    };
    # Nextcloud needs to know it's behind HTTPS (edge terminates TLS)
    https = lib.mkForce true;
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
        ;
    };
  };

  # Security headers are set on edge (TLS termination point)
}
