{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  mc-bkp = pkgs.callPackage ./mc-bkp.nix { };

  inherit (lib) mkDefault;
in
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

  config = {
    environment.systemPackages = [
      mc-bkp
      pkgs.kitty # This is a bad idea, but fixes `missing or unsuitable terminal: xterm-kitty` when using tmux
      pkgs.tmux
    ];

    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "minecraft-server" ];

    services.minecraft-servers = {
      enable = mkDefault true;
      eula = mkDefault true;
      openFirewall = mkDefault true;
    };
  };
}
