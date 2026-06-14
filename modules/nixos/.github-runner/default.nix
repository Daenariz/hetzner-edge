{ config, lib, ... }:

let
  cfg = config.services.github-runners;
  enabled = lib.filterAttrs (_: r: r.enable) cfg;

  inherit (lib)
    mapAttrs'
    mapAttrsToList
    mkIf
    nameValuePair
    unique
    ;
in
{
  config = mkIf (enabled != { }) {
    users.groups = mapAttrs' (_: r: nameValuePair r.group { }) enabled;
    users.users = mapAttrs' (
      name: r:
      nameValuePair r.user {
        isSystemUser = true;
        inherit (r) group;
        home = "/var/lib/github-runner/${name}";
        createHome = true;
        description = "GitHub Runner (${name})";
      }
    ) enabled;

    nix.settings.trusted-users = unique (mapAttrsToList (_: r: r.user) enabled);
  };
}
