{
  outputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.minecraft-servers;
  survival = cfg.servers.survival;

  # operators are also whitelisted on the creative server
  ops = [
    "N3071GHT"
    "Xerion42"
    "_sud0"
  ];

  getUuid = name: survival.whitelist.${name};

  mkOps =
    names:
    lib.genAttrs names (name: {
      uuid = getUuid name;
      level = 4;
    });

  mkWhitelist = names: lib.genAttrs names (name: getUuid name);
in
{
  imports = [ outputs.nixosModules.minecraft-servers ];

  services.minecraft-servers = {
    servers = {
      survival = {
        enable = true;
        package = pkgs.fabricServers.fabric-1_21_11;
        jvmOpts = "-Xms4G -Xmx16G -XX:+UseG1GC";
        serverProperties = {
          gamemode = "survival";
          difficulty = "hard";
          simulation-distance = "16";
          level-seed = "28618658336713097";
          server-port = 25565;
          white-list = true;
        };
        whitelist = {
          Angiiiii = "956a108f-1b34-411b-97ea-08ab14484d4f";
          JonShakespeare = "8578f586-dcaa-46c7-992b-77c98737b226";
          Morschlitz98 = "ec39f163-1cae-4673-8d7e-a626f706eac1";
          N3071GHT = "f4fc9eb2-8d82-49a6-8061-72c490ea5f9a";
          PureAcid = "cea52bd2-fabb-43cd-81d9-aeb0978a620b";
          SherlockEmmy97 = "ac6688ab-5f0b-49c3-ba04-720aaba1b0a7";
          Sutaneko = "6c7e30b0-48ff-492a-8224-b6aa09346e7a";
          Xerion42 = "7f7112c3-4089-4510-a94f-78955aa1c205";
          _Inabakumori_ = "959100a9-5245-408e-8746-443b94f5ccc2";
          _sud0 = "a9e1b5fd-5e53-491c-9ef3-7c57c39687f0";
        };
        operators = mkOps ops;
        symlinks = {
          mods = pkgs.linkFarmFromDrvs "mods" (
            builtins.attrValues {
              Fabric-Carpet = pkgs.fetchurl {
                url = "https://cdn.modrinth.com/data/TQTTVgYE/versions/HzPcczDK/fabric-carpet-1.21.11-1.4.194%2Bv251223.jar";
                sha256 = "1B4D66F0332BDA5DEEE08755E493C2D6AC64D64D5285E1134AA03604975C2521";
              };
            }
          );
        };
      };

      creative = {
        enable = true;
        inherit (survival) package operators symlinks;
        jvmOpts = "-Xms2G -Xmx8G -XX:+UseG1GC";
        serverProperties = survival.serverProperties // {
          gamemode = "creative";
          server-port = 25566;
        };
        whitelist = mkWhitelist ops;
      };

      amplified = {
        enable = true;
        inherit (survival) package operators symlinks whitelist jvmOpts;
        serverProperties = survival.serverProperties // {
          difficulty = "normal";
          level-seed = "646305128";
          level-type = "minecraft:amplified";
          server-port = 25567;
        };
      };
    };
  };
}
