{ outputs, config, ... }:

{
  imports = [ outputs.nixosModules.nix-gitlab-runner ];

  services.nix-gitlab-runner = {
    enable = true;
    authenticationTokenConfigFile = config.sops.templates."gitlab-runner/authentication-token-config".path;
  };

  sops = {
    secrets = {
      "gitlab-runner/ci-server-url" = { };
      "gitlab-runner/ci-server-token" = { };
    };
    templates."gitlab-runner/authentication-token-config" = {
      content = ''
        CI_SERVER_URL=${config.sops.placeholder."gitlab-runner/ci-server-url"}
        CI_SERVER_TOKEN=${config.sops.placeholder."gitlab-runner/ci-server-token"}
      '';
    };
  };
}
