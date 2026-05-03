{ outputs, config, ... }:

{
  imports = [ outputs.nixosModules.vaultwarden ];

  services.vaultwarden = {
    enable = true;
    reverseProxy = {
      enable = true;
      subdomain = "vault";
    };
    mailIntegration = {
      enable = true;
      smtpHost = config.mailserver.fqdn;
    };
    # backupDir = "/data/backup/vaultwarden"; # FIXME
  };
}
