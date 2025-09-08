{
  systemType = "x86_64-linux"; # This is used for the value of "system" in the flake.nix file.
  __functor = self: {
    config,
    pkgs,
    inputs,
    ...
  }: {
    inherit (self) systemType;

    usersToExclude = ["saige" "nixos"]; # Exclude these users from users/globals

    imports = [
      inputs.arion.nixosModules.arion
    ];

    environment.systemPackages = with pkgs; [
      # Add your system packages here
      git
      wget
      curl
      btop
      fastfetch
      nixd
    ];

    fileSystems."/mnt/share" = {
      device = "//10.177.177.112/magicbox";
      fsType = "cifs";
      options = let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
        # CIFS options for proper permissions
        cifs_opts = "uid=1000,gid=100,file_mode=0664,dir_mode=0775";
      in ["${automount_opts},${cifs_opts},credentials=/etc/nixos/smb-secrets"];
    };
    nix.settings.trusted-users = ["nixos" "nea" "magicbox"];

    programs.nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs; # only for NixOS 24.05
    };

    modules.fd.enable = true; # Enable fd file search

    system.activationScripts.directoryConfig.text = ''
      # Create local directories
      mkdir -p /home/magicbox/config
      mkdir -p /home/magicbox/data
      mkdir -p /home/magicbox/data/caddy
      mkdir -p /home/magicbox/config/prowlarr
      mkdir -p /home/magicbox/config/sonarr
      mkdir -p /home/magicbox/config/radarr
      mkdir -p /home/magicbox/config/lidarr
      mkdir -p /home/magicbox/config/sabnzbd
      mkdir -p /home/magicbox/config/caddy
      mkdir -p /home/magicbox/config/jellyfin

      # Create media directory in the CIFS share (ensure mount is available)
      mkdir -p /mnt/share/media
      mkdir -p /mnt/share/media/usenet

      # Set ownership for local directories
      chown -R 1000:100 /home/magicbox/config
      chown -R 1000:100 /home/magicbox/data
      chmod -R 755 /home/magicbox/config
      chmod -R 755 /home/magicbox/data

      # Set ownership and permissions for the shared media directory
      # Note: CIFS permissions depend on mount options and server configuration
      chown -R 1000:100 /mnt/share/media || true
      chmod -R 755 /mnt/share/media || true
    '';

    users.users.magicbox = {
      isNormalUser = true;
      description = "magicbox";
      extraGroups = ["networkmanager" "wheel" "docker"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxMQi0MHfKIz2Fl9zvViseJButXB13nSRQ0qNripZij magicbox@10.177.177.39"
      ];
    };

    services.openssh.enable = true;

    virtualisation.arion = {
      backend = "docker";
      projects.magicbox = {
        serviceName = "magicbox";
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
                "/home/magicbox/config/caddy/Caddyfile:/etc/caddy/Caddyfile"
                "/home/magicbox/data/caddy:/data"
              ];
            };
            prowlarr = {
              service.container_name = "prowlarr";
              service.image = "linuxserver/prowlarr:latest";
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
                "/home/magicbox/config/prowlarr:/config"
              ];
            };
            sonarr = {
              service.container_name = "sonarr";
              service.image = "linuxserver/sonarr:latest";
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
                "/home/magicbox/config/sonarr:/config"
                "/mnt/share/media:/data"
              ];
            };
            radarr = {
              service.container_name = "radarr";
              service.image = "linuxserver/radarr:latest";
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
                "/home/magicbox/config/radarr:/config"
                "/mnt/share/media:/data"
              ];
            };
            lidarr = {
              service.container_name = "lidarr";
              service.image = "linuxserver/lidarr:latest";
              service.restart = "unless-stopped";
              service.environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              service.ports = [
                "8686:8686"
              ];
              service.networks = [
                "magicbox-network"
              ];
              service.volumes = [
                "/home/magicbox/config/lidarr:/config"
                "/mnt/share/media:/data"
              ];
            };
            sabnzbd = {
              service.container_name = "sabnzbd";
              service.image = "linuxserver/sabnzbd:latest";
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
                "/home/magicbox/config/sabnzbd:/config"
                "/mnt/share/media/usenet:/data/usenet:rw"
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
