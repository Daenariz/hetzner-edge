{ inputs, ... }:

{
  imports = [ inputs.synix.nixosModules.radicale ];

  services.radicale = {
    enable = true;
    reverseProxy = {
      enable = true;
      subdomain = "dav";
    };
    users = [
      "pascal"
      "portuus"
      "susagi"
      "steffen"
      "ulm"
    ];
  };
}
