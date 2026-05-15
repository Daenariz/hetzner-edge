# TCP/UDP stream proxy: forwards non-HTTP traffic over Tailnet to portuus.
# Requires nginx stream module.
{ constants, ... }:

let
  c = constants;
  ip = c.hosts.portuus.ip;
  rd = c.services.rustdesk.ports;
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

      # GitLab SSH (port 2222 on edge -> port 2299 on portuus)
      server { listen ${toString mc.gitlab.sshPort}; proxy_pass ${ip}:2299; }

      # Minecraft
      server { listen ${toString mc.minecraft-survival.port}; proxy_pass ${ip}:${toString mc.minecraft-survival.port}; }
      server { listen ${toString mc.minecraft-creative.port}; proxy_pass ${ip}:${toString mc.minecraft-creative.port}; }
      server { listen ${toString mc.minecraft-amplified.port}; proxy_pass ${ip}:${toString mc.minecraft-amplified.port}; }

      # Rustdesk
      server { listen ${toString rd.nat-test};  proxy_pass ${ip}:${toString rd.nat-test}; }
      server { listen ${toString rd.id};        proxy_pass ${ip}:${toString rd.id}; }
      server { listen ${toString rd.id} udp;    proxy_pass ${ip}:${toString rd.id}; }
      server { listen ${toString rd.relay};     proxy_pass ${ip}:${toString rd.relay}; }
      server { listen ${toString rd.ws};        proxy_pass ${ip}:${toString rd.ws}; }
      server { listen ${toString rd.ws-relay};  proxy_pass ${ip}:${toString rd.ws-relay}; }
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      m.smtp
      m.submission-tls
      m.submission
      m.imap
      mc.gitlab.sshPort
      mc.minecraft-survival.port
      mc.minecraft-creative.port
      mc.minecraft-amplified.port
      rd.nat-test
      rd.id
      rd.relay
      rd.ws
      rd.ws-relay
    ];
    allowedUDPPorts = [
      rd.id
    ];
  };
}
