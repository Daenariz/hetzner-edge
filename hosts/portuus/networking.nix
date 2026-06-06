{ constants, ... }:

let
  c = constants;
in
{
  networking = {
    hostName = "portuus";
    inherit (c) domain;
    hostId = "cec23325"; # ZFS requires a host id
  };
}
