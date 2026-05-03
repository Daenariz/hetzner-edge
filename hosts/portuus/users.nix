{ inputs, ... }:

{
  imports = [
    inputs.synix.nixosModules.normalUsers

    ../../users/pascal
    ../../users/steffen
    ../../users/ulm
  ];
}
