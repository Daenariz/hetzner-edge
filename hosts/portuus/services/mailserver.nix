{ inputs, lib, ... }:

{
  imports = [ inputs.synix.nixosModules.mailserver ];

  mailserver = {
    enable = true;
    stateVersion = 3;
    # TLS certs from previous ACME run; edge handles ACME renewal going forward
    certificateScheme = lib.mkForce "manual";
    certificateFile = "/var/lib/acme/mail.portuus.de/fullchain.pem";
    keyFile = "/var/lib/acme/mail.portuus.de/key.pem";
    _accounts = {
      info = {
        aliases = [ "postmaster" ];
      };
      steffen = {
        aliases = [ "postmaster" ];
      };
      jfk = { };
      lissy = { };
      ulm = { };
      nextcloud = {
        sendOnly = true;
      };
      vaultwarden = {
        sendOnly = true;
      };
      firefly-iii = {
        sendOnly = true;
      };
      gitlab = {
        sendOnly = true;
      };
    };
  };
}
