{
  inputs,
  pkgs,
  config,
  ...
}:

{
  imports = [ inputs.synix.nixosModules.tailscale ];

  services.tailscale = {
    enable = true;
    tailnets.portuus = {
      loginServer = "https://hs.portuus.de";
      authKeyFile = config.sops.secrets."tailscale/auth-key".path;
      enableSSH = true;
      default = true;
    };
  };

  sops.secrets."tailscale/auth-key" = { };

  # Block TPM access for tailscaled to prevent state encryption.
  # TPM lockout occurs on unclean shutdowns (server freezes), making
  # tailscaled unable to start until the state file is manually deleted.
  systemd.services.tailscaled.serviceConfig.DeviceDeny = [
    "/dev/tpmrm0"
    "/dev/tpm0"
  ];

  environment.systemPackages = with pkgs; [
    kitty # to be able to copy term info
  ];
}
