{
  inputs,
  config,
  lib,
  ...
}:

{
  imports = [ inputs.synix.nixosModules.mailserver ];

  mailserver = {
    enable = true;
    stateVersion = 3;
    # TLS certs from previous ACME run; edge handles ACME renewal going forward
    x509 = {
      useACMEHost = lib.mkForce null;
      certificateFile = "/var/lib/acme/mail.portuus.de/fullchain.pem";
      privateKeyFile = "/var/lib/acme/mail.portuus.de/key.pem";
    };
    _accounts = {
      info = {
        aliases = [ "postmaster" ];
      };
      steffen = {
        aliases = [ "postmaster" ];
      };
      lissy = { };
      ulm = { };
      nextcloud = {
        sendOnly = true;
      };
      vaultwarden = {
        sendOnly = true;
      };
      gitlab = {
        sendOnly = true;
      };
    };
    # ─── BEGIN workaround: synix-26.05 mailserver wrapper ───────────────────
    # synix sets the now-readOnly `accounts.<x>.name`, which trips when
    # postfix reads it for sendOnly accounts. Override the whole map without
    # `name` until synix is patched. Remove this block once upstream is fixed.
    accounts = lib.mkForce (
      lib.mapAttrs' (
        user: cfg:
        let
          inherit (config.networking) domain;
        in
        lib.nameValuePair "${user}@${domain}" {
          aliases = map (alias: "${alias}@${domain}") cfg.aliases;
          inherit (cfg) sendOnly;
          quota = "5G";
          hashedPasswordFile = config.sops.secrets."mailserver/accounts/${user}".path;
        }
      ) config.mailserver._accounts
    );
    # ─── END workaround ─────────────────────────────────────────────────────
  };
}
