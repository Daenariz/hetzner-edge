{ inputs, ... }:

{
  imports = [ inputs.synix.nixosModules.openssh ];

  services.openssh.enable = true;
}
