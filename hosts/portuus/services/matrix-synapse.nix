{
  inputs,
  config,
  lib,
  ...
}:

{
  imports = [
    inputs.synix.nixosModules.matrix-synapse
    inputs.synix.nixosModules.maubot
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  services.matrix-synapse = {
    enable = true;
    sops = true;
    dataDir = "/data/matrix-synapse";
    coturn.enable = true;
    bridges = {
      whatsapp = {
        enable = true;
        admin = "@steffen:portuus.de";
      };
      signal = {
        enable = true;
        admin = "@steffen:portuus.de";
      };
    };
  };

  services.maubot = {
    enable = true;
    sops = true;
    dataDir = "/data/maubot";
    admins = [
      "steffen"
    ];
    plugins = with config.services.maubot.package.plugins; [
      gitlab
      reminder
    ];
  };

  # TODO: nix-core: toggle user if coturn and synapse are not running on the same machine
  sops.secrets."coturn/static-auth-secret" = {
    owner = lib.mkForce "matrix-synapse";
    group = lib.mkForce "matrix-synapse";
  };
}
