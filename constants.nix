rec {
  domain = "portuus.de";

  hosts = {
    portuus = {
      ip = "100.64.0.2";
    };
    edge = {
      ip = "100.64.0.1";
    };
    jetkvm = {
      ip = "100.64.0.6";
    };
  };

  services = {
    gitlab = {
      subdomain = "git";
      fqdn = "git." + domain;
    };
    gitlab-pages = {
      subdomain = "pages";
      fqdn = "pages." + domain;
      port = 8090;
    };
    headscale = {
      subdomain = "hs";
      fqdn = "hs." + domain;
    };
    immich = {
      subdomain = "gallery";
      fqdn = "gallery." + domain;
      port = 2283;
    };
    jirafeau = {
      subdomain = "share";
      fqdn = "share." + domain;
    };
    matrix-synapse = {
      fqdn = domain;
      port = 8008;
    };
    maubot = {
      port = 29316;
    };
    minecraft-survival = {
      port = 25565;
    };
    minecraft-creative = {
      port = 25566;
    };
    nextcloud = {
      subdomain = "cloud";
      fqdn = "cloud." + domain;
    };
    radicale = {
      subdomain = "dav";
      fqdn = "dav." + domain;
    };
    rustdesk = {
      ports.nat-test = 21115;
      ports.id = 21116;
      ports.relay = 21117;
      ports.ws = 21118;
      ports.ws-relay = 21119;
    };
    vaultwarden = {
      subdomain = "vault";
      fqdn = "vault." + domain;
      port = 8222;
    };
  };

  mail = {
    smtp = 25;
    submission-tls = 465;
    submission = 587;
    imap = 993;
  };
}
