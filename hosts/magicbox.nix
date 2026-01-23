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
      htop
    ];

    # fileSystems."/mnt/share" = {
    #   device = "10.177.177.112:/mnt/internal/disk1/magicbox";
    #   fsType = "nfs";
    #   options = ["x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s"];
    # };
    # # optional, but ensures rpc-statsd is running for on demand mounting
    # boot.supportedFilesystems = [ "nfs" ];

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
      #package = pkgs.nix-ld-rs; # only for NixOS 24.05
    };

    modules.fd.enable = true; # Enable fd file search

    system.activationScripts.directoryConfig.text = ''
      # Create local directories
      mkdir -p /home/magicbox/config
      mkdir -p /home/magicbox/data
      mkdir -p /home/magicbox/data/caddy
      mkdir -p /home/magicbox/data/jellyfin
      mkdir -p /home/magicbox/data/zurg-testing
      mkdir -p /home/magicbox/config/prowlarr
      mkdir -p /home/magicbox/config/sonarr
      mkdir -p /home/magicbox/config/radarr
      mkdir -p /home/magicbox/config/lidarr
      mkdir -p /home/magicbox/config/sabnzbd
      mkdir -p /home/magicbox/config/jellyfin
      # Create media directory in the CIFS share (ensure mount is available)
      mkdir -p /mnt/share/media
      mkdir -p /mnt/share/media/movies
      mkdir -p /mnt/share/media/tv
      mkdir -p /mnt/share/media/music
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
    services.openssh.settings.PermitRootLogin = "yes";

    # Tailscale
    networking.firewall.checkReversePath = "loose";
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };

    virtualisation.arion = {
      backend = "docker";
      projects.zurg = {
        serviceName = "zurg";
        settings = {
          project.name = "zurg";
          networks.zurg-network = {
            name = "zurg-network";
          };
          services = {
            zurg.service = {
              container_name = "zurg";
              image = "ghcr.io/debridmediamanager/zurg-testing:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              networks = [
                "zurg-network"
              ];
              volumes = [
                "/home/magicbox/config/zurg-testing/config.yml:/app/config.yml"
                "/home/magicbox/data/zurg-testing:/app/data"
              ];
            };
            rclone.service = {
              container_name = "rclone";
              image = "rclone/rclone:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              networks = [
                "zurg-network"
              ];
              depends_on = [
                "zurg"
              ];
              capabilities = {
                SYS_ADMIN = true;
              };
              devices = [
                "/dev/fuse:/dev/fuse:rwm"
              ];
              volumes = [
                "/mnt/zurg:/data:rshared"
                "/home/magicbox/config/zurg-testing/rclone.conf:/config/rclone/rclone.conf"
              ];
              command = [
                "mount"
                "zurg:"
                "/data"
                "--allow-other"
                "--allow-non-empty"
                "--dir-cache-time"
                "10s"
                "--vfs-cache-mode"
                "full"
              ];
            };
            rclone.out.service = {
              security_opt = [
                "apparmor=unconfined"
              ];
            };
          };
        };
      };
      projects.magicbox = {
        serviceName = "magicbox";
        settings = {
          project.name = "magicbox";
          networks.magicbox-network = {
            name = "magicbox-network";
          };
          services = {
            caddy.service = {
              container_name = "caddy";
              image = "ghcr.io/caddybuilds/caddy-cloudflare:latest";
              restart = "unless-stopped";
              command = [ "caddy" "run" "--config" "/etc/caddy/Caddyfile" "--adapter" "caddyfile" "--envfile" "/etc/caddy/secrets.env" ];
              ports = [
                "80:80"
                "443:443"
              ];
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/config/caddy/Caddyfile:/etc/caddy/Caddyfile"
                "/home/magicbox/config/caddy/secrets.env:/etc/caddy/secrets.env"
                "/home/magicbox/data/caddy:/data"
              ];
            };
            jellyfin.service = {
              container_name = "jellyfin";
              image = "linuxserver/jellyfin:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
                DOCKER_MODS = "linuxserver/mods:jellyfin-opencl-intel";
                JELLYFIN_PublishedServerUrl = "https://stream.nea.rip";
              };
              # ports = [
              #   "8096:8096"
              # ];
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/config/jellyfin:/config"
                "/home/magicbox/data/jellyfin:/cache"
                "/mnt/share/media:/data"
                "/mnt/zurg:/media"
              ];
              devices = [
                "/dev/dri:/dev/dri"
              ];
            };
            prowlarr.service = {
              container_name = "prowlarr";
              image = "linuxserver/prowlarr:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              # ports = [
              #   "9696:9696"
              # ];
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/config/prowlarr:/config"
              ];
            };
            sonarr.service = {
              container_name = "sonarr";
              image = "linuxserver/sonarr:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              # ports = [
              #   "8989:8989"
              # ];
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/config/sonarr:/config"
                "/mnt/share/media:/data"
              ];
            };
            radarr.service = {
              container_name = "radarr";
              image = "linuxserver/radarr:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              # ports = [
              #   "7878:7878"
              # ];
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/config/radarr:/config"
                "/mnt/share/media:/data"
              ];
            };
            lidarr.service = {
              container_name = "lidarr";
              image = "linuxserver/lidarr:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              # ports = [
              #   "8686:8686"
              # ];
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/config/lidarr:/config"
                "/mnt/share/media:/data"
              ];
            };
            mylar.service = {
              container_name = "mylar";
              image = "linuxserver/mylar:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              # ports = [
              #   "8090:8090"
              # ];
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/config/mylar:/config"
                "/mnt/share/media:/data"
              ];
            };
            bazarr.service = {
              container_name = "bazarr";
              image = "linuxserver/bazarr:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              # Refuses to work behind reverse proxy?
              ports = [
                "6767:6767"
              ];
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/config/bazarr:/config"
                "/mnt/share/media:/data"
              ];
            };
            sabnzbd.service = {
              container_name = "sabnzbd";
              image = "linuxserver/sabnzbd:latest";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              # ports = [
              #   "8080:8080"
              # ];
              networks = [
                "magicbox-network"
              ];
              volumes = [
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
