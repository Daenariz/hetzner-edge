{
  outputs,
  ...
}:

{
  imports = [
    ./coturn.nix
    ./headscale.nix
    # ./jetkvm-proxy.nix
    ./nginx.nix
    ./openssh.nix
    ./futro-proxy.nix
    ./stream-proxy.nix

    outputs.nixosModules.tailscale
  ];
}
