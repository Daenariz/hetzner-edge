{ inputs, lib, ... }:

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
    accounts' = {
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
  };
}
