{
  outputs,
  ...
}:

{
  imports = [
    ./coturn.nix
    ./headscale.nix
    ./jetkvm-proxy.nix
    ./nginx.nix
    ./openssh.nix

    outputs.nixosModules.tailscale
  ];
}
