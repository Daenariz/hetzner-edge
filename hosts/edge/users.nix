{ inputs, ... }:

{
  imports = [
    inputs.synix.nixosModules.normalUsers

    ../../users/susagi
  ];
}
