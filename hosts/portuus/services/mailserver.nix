{ inputs, ... }:

{
  imports = [ inputs.synix.nixosModules.mailserver ];

  mailserver = {
    enable = true;
    stateVersion = 3;
    accounts = {
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
