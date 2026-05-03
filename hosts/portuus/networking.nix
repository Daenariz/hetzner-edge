let
  c = import ../../constants.nix;
in
{
  networking.hostName = "portuus";
  networking.domain = c.domain;
  networking.hostId = "cec23325"; # ZFS requires a host id
}
