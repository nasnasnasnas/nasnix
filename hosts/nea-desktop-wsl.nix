{
  systemType = "x86_64-linux"; # This is used for the value of "system" in the flake.nix file.
  __functor = self: {
    config,
    pkgs,
    inputs,
    ...
  }: {
    inherit (self) systemType;

    usersToExclude = ["saige"]; # Exclude these users from users/globals

    imports = [
      inputs.nixos-wsl.nixosModules.default
      inputs.arion.nixosModules.arion
    ];

    wsl.enable = true;
    wsl.defaultUser = "nixos";

    environment.systemPackages = with pkgs; [
      # Add your system packages here
      git
      wget
      curl
      btop
      fastfetch
    ];

    programs.nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs; # only for NixOS 24.05
    };

    modules.fd.enable = true; # Enable fd file search

    users.extraUsers.nixos.extraGroups = ["docker"];

    virtualisation.arion = {
      backend = "docker";
      projects.magicbox = {
        serviceName =  "magicbox";
        settings = {
          project.name = "magicbox";
          networks.magicbox-network = {
            name = "magicbox-network";
          };
          services = {
            caddy = {
              service.container_name = "caddy";
              service.image = "caddy:latest";
              service.restart = "unless-stopped";
              service.ports = [
                "80:80"
                "443:443"
              ];
              service.networks = [
                "magicbox-network"
              ];
              service.volumes = [
                "/config/caddy:/etc/caddy"
                "/data/caddy:/data"
              ];
            };
            prowlarr = {
              service.container_name = "prowlarr";
              service.image = "lcsr.io/linuxserver/prowlarr:latest";
              service.restart = "unless-stopped";
              service.environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              service.ports = [
                "9696:9696"
              ];
              service.networks = [
                "magicbox-network"
              ];
              service.volumes = [
                "/config/prowlarr:/config"
              ];
            };
            sonarr = {
              service.container_name = "sonarr";
              service.image = "lcsr.io/linuxserver/sonarr:latest";
              service.restart = "unless-stopped";
              service.environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              service.ports = [
                "8989:8989"
              ];
              service.networks = [
                "magicbox-network"
              ];
              service.volumes = [
                "/config/sonarr:/config"
                "/data/media:/data"
              ];
            };
            radarr = {
              service.container_name = "radarr";
              service.image = "lcsr.io/linuxserver/radarr:latest";
              service.restart = "unless-stopped";
              service.environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              service.ports = [
                "7878:7878"
              ];
              service.networks = [
                "magicbox-network"
              ];
              service.volumes = [
                "/config/radarr:/config"
                "/data/media:/data"
              ];
            };
            sabnzbd = {
              service.container_name = "sabnzbd";
              service.image = "lcsr.io/linuxserver/sabnzbd:latest";
              service.restart = "unless-stopped";
              service.environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              service.ports = [
                "8080:8081"
              ];
              service.networks = [
                "magicbox-network"
              ];
              service.volumes = [
                "/config/sabnzbd:/config"
                "/data/media/usenet:/data/usenet:rw"
              ];
            };
          };
        };
      };
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
