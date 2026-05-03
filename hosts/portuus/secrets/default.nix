{ inputs, ... }:

{
  imports = [ inputs.synix.nixosModules.sops ];
}
