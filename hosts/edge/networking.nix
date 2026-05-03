let
  c = import ../../constants.nix;
in
{
  networking.hostName = "edge";
  networking.domain = c.domain;
}
