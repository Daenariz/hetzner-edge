{ constants, ... }:

let
  c = constants;
in
{
  networking.hostName = "edge";
  networking.domain = c.domain;
}
