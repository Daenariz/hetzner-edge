# TODO: turn into module for nix-core
# TODO: add assertion: --key/-k cannot be in extraArgs

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.rustdesk-server;

  keyFile = config.sops.secrets."rustdesk-server/key".path;
  relayArg = builtins.concatStringsSep ":" cfg.signal.relayHosts;
in
{
  sops.secrets."rustdesk-server/key" = {
    owner = "rustdesk";
    group = "rustdesk";
    mode = "0440";
    restartUnits = [
      "rustdesk-signal.service"
      "rustdesk-relay.service"
    ];
  };

  services.rustdesk-server = {
    enable = true;
    openFirewall = false; # traffic comes via edge stream proxy
    signal = {
      enable = true;
      relayHosts = [ config.networking.domain ];
    };
    relay = {
      enable = true;
    };
  };

  systemd.services.rustdesk-signal.serviceConfig.ExecStart = lib.mkForce ''
    ${pkgs.bash}/bin/bash -c "${cfg.package}/bin/hbbs --relay-servers ${relayArg} --key $(${pkgs.coreutils}/bin/cat ${keyFile}) ${lib.escapeShellArgs cfg.signal.extraArgs}"
  '';

  systemd.services.rustdesk-relay.serviceConfig.ExecStart = lib.mkForce ''
    ${pkgs.bash}/bin/bash -c "${cfg.package}/bin/hbbr --key $(${pkgs.coreutils}/bin/cat ${keyFile}) ${lib.escapeShellArgs cfg.relay.extraArgs}"
  '';
}
