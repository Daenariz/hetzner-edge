{ config, lib, ... }:

let
  cfg = config.services.github-runners;
  enabled = lib.filterAttrs (_: r: r.enable) cfg;
  names = builtins.attrNames enabled;

  inherit (lib)
    genAttrs
    mapAttrs
    mkDefault
    mkIf
    ;
in
{
  config = mkIf (enabled != { }) {
    services.github-runners = mapAttrs (name: _: {
      user = mkDefault name;
      group = mkDefault name;
    }) enabled;

    users.groups = genAttrs names (_: { });
    users.users = genAttrs names (name: {
      isSystemUser = true;
      group = name;
      home = "/var/lib/github-runner/${name}";
      createHome = true;
      description = "GitHub Runner (${name})";
    });

    nix.settings.trusted-users = names;
  };
}
