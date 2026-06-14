# TCP/UDP stream proxy: forwards non-HTTP traffic over Tailnet to futro.
# Requires nginx stream module.
{ constants, ... }:

let
  c = constants;
  ip = c.hosts.futro.ip;
  # rd = c.services.rustdesk.ports;
  mc = c.services;
  m = c.mail;
in
{
  services.nginx = {
    streamConfig = ''
      # Mail
      server { listen ${toString m.smtp};           proxy_pass ${ip}:${toString m.smtp}; }
      server { listen ${toString m.submission};      proxy_pass ${ip}:${toString m.submission}; }
      server { listen ${toString m.submission-tls};  proxy_pass ${ip}:${toString m.submission-tls}; }
      server { listen ${toString m.imap};            proxy_pass ${ip}:${toString m.imap}; }
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      m.smtp
      m.submission-tls
      m.submission
      m.imap
    ];
    allowedUDPPorts = [
    ];
  };
}
