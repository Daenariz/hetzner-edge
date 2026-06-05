{
  outputs,
  config,
  constants,
  ...
}:

let
  c = constants;
  s = c.services.vaultwarden;
in
{
  imports = [ outputs.nixosModules.vaultwarden ];

  services.vaultwarden = {
    enable = true;
    reverseProxy = {
      enable = true;
      inherit (s) subdomain;
      forceSSL = false; # TLS terminated on edge
    };
    # Vaultwarden needs to know the public URL is HTTPS
    config.DOMAIN = "https://${s.fqdn}";
    mailIntegration = {
      enable = true;
      smtpHost = config.mailserver.fqdn;
    };
  };
}
