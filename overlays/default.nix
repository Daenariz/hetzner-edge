{ inputs, ... }:

{
  # synix packages accessible through 'pkgs.synix'
  synix-packages = final: prev: { synix = inputs.synix.packages."${final.system}"; };

  # packages in `pkgs/` accessible through 'pkgs.local'
  local-packages = final: prev: { local = import ../pkgs { pkgs = final; }; };

  # https://nixos.wiki/wiki/Overlays
  modifications =
    final: prev:
    let
      files = [
      ];
      imports = builtins.map (f: import f final prev) files;
    in
    builtins.foldl' (a: b: a // b) { } imports // inputs.synix.overlays.modifications final prev;

  # old-stable nixpkgs accessible through 'pkgs.old-stable'
  old-stable-packages = final: prev: {
    old-stable = import inputs.nixpkgs-old-stable {
      inherit (final) system;
      inherit (prev) config;
    };
  };

  # unstable nixpkgs accessible through 'pkgs.unstable'
  unstable-packages = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      inherit (prev) config;
    };
  };
}
