{
  writeShellApplication,
  coreutils,
  gnutar,
  gzip,
  ...
}:

let
  name = "mc-bkp";
  text = builtins.readFile ./${name}.sh;
in
writeShellApplication {
  inherit name text;
  meta.mainProgram = name;

  runtimeInputs = [
    coreutils
    gnutar
    gzip
  ];
}
