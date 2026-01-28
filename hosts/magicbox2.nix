{
  systemType = "x86_64-linux"; # This is used for the value of "system" in the flake.nix file.
  __functor = self: {
    config,
    pkgs,
    inputs,
    ...
  }: {
    inherit (self) systemType;

    usersToExclude = ["leah" "nea" "nixos"]; # Exclude these users from users/globals

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
      ffmpeg-full
      dua
      damon # TUI for Nomad.
    ];

    # fileSystems."/mnt/share" = {
    #   device = "10.177.177.112:/mnt/internal/disk1/magicbox";
    #   fsType = "nfs";
    #   options = ["x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s"];
    # };
    # # optional, but ensures rpc-statsd is running for on demand mounting
    # boot.supportedFilesystems = [ "nfs" ];

    # fileSystems."/mnt/share" = {
    #   device = "//10.177.177.112/magicbox";
    #   fsType = "cifs";
    #   options = let
    #     # this line prevents hanging on network split
    #     automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    #     # CIFS options for proper permissions
    #     cifs_opts = "uid=1000,gid=100,file_mode=0664,dir_mode=0775";
    #   in ["${automount_opts},${cifs_opts},credentials=/etc/nixos/smb-secrets"];
    # };
    nix.settings.trusted-users = [ "nixos" "nea" "magicbox" ];

    programs.nix-ld = {
      enable = true;
      #package = pkgs.nix-ld-rs; # only for NixOS 24.05
    };

    modules.fd.enable = true; # Enable fd file search

    system.activationScripts.directoryConfig.text = ''
      # Create local directories
      # mkdir -p /home/magicbox/config
      # mkdir -p /home/magicbox/data
      # mkdir -p /home/magicbox/data/caddy
      # mkdir -p /home/magicbox/data/jellyfin
      # mkdir -p /home/magicbox/data/zurg-testing
      # mkdir -p /home/magicbox/config/prowlarr
      # mkdir -p /home/magicbox/config/sonarr
      # mkdir -p /home/magicbox/config/radarr
      # mkdir -p /home/magicbox/config/lidarr
      # mkdir -p /home/magicbox/config/sabnzbd
      # mkdir -p /home/magicbox/config/jellyfin
      # mkdir -p /home/magicbox/config/caddy
      # mkdir -p /home/magicbox/config/zurg-testing
      # mkdir -p /home/magicbox/config/mylar
      # mkdir -p /home/magicbox/config/bazarr

      # mkdir -p /home/magicbox/media
      # mkdir -p /home/magicbox/manual-media
      
      # Create media directory in the CIFS share (ensure mount is available)
      # mkdir -p /mnt/share/media
      # mkdir -p /mnt/share/media/movies
      # mkdir -p /mnt/share/media/tv
      # mkdir -p /mnt/share/media/music
      # mkdir -p /mnt/share/media/usenet
    
      # mkdir -p /mnt/zurg
      
      # Set ownership for local directories
      chown -R 1000:100 /home/magicbox/config
      chown -R 1000:100 /home/magicbox/data
      chown -R 1000:100 /home/magicbox/media
      chown -R 1000:100 /home/magicbox/manual-media
      chmod -R 755 /home/magicbox/config
      chmod -R 755 /home/magicbox/data
      chmod -R 755 /home/magicbox/media
      chmod -R 755 /home/magicbox/manual-media

      sudo umount -l /mnt/zurg || true
      chown -R 1000:100 /mnt/zurg || true
      chmod -R 755 /mnt/zurg || true
      ''; 

    users.users.magicbox = {
      isNormalUser = true;
      description = "magicbox";
      extraGroups = ["networkmanager" "wheel" "docker"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxMQi0MHfKIz2Fl9zvViseJButXB13nSRQ0qNripZij magicbox@10.177.177.54"
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

    programs.fuse.enable = true;
    programs.fuse.userAllowOther = true;



    # services.nomad = {
    #   enable = true;
    #   enableDocker = true;
      
    #   dropPrivileges = false;

    #   settings = {
    #     client.enabled = true;
    #     server = {
    #       enabled = true;
    #       bootstrap_expect = 1;
    #     };
    #   };
    # };

    virtualisation.arion = {
      backend = "docker";
      
      projects.magicbox = {
        serviceName =  "magicbox";
        settings = {
          project.name = "magicbox";
          networks.magicbox-network = {
            name = "magicbox-network";
          };
          networks.zurg = {
            name = "zurg";
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
            termix.service = {
              container_name = "termix";
              image = "ghcr.io/lukegus/termix:latest";
              restart = "unless-stopped";
              environment = {
                PORT = "8080";
              };
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/data/termix:/app/data"
              ];
            };
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
                "zurg"
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
                "zurg"
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
                "--poll-interval"
                "15s"
                "--umask"
                "000"
                "--vfs-cache-mode"
                "full"
              ];
            };
            rclone.out.service = {
              security_opt = [
                "apparmor=unconfined"
              ];
            };
            nzbdav.service = {
              container_name = "nzbdav";
              image = "nzbdav/nzbdav:latest";
              restart = "unless-stopped";
              healthcheck = {
                test = [ "CMD-SHELL" "curl" "-f" "http://localhost:3000/health" "||" "exit" "1" ];
                interval = "1m";
                retries = 3;
                start_period = "5s";
                timeout = "5s";
              };
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              networks = [
                "magicbox-network"
              ];
              volumes = [
                "/home/magicbox/config/nzbdav:/config"
                "/mnt/nzbdav:/mnt/nzbdav:rshared"
                "/home/magicbox/media:/data"
              ];
            };
            nzbdav-rclone.service = {
              image = "rclone/rclone:latest";
              container_name = "nzbdav-rclone";
              restart = "unless-stopped";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
              };
              networks = [
                "magicbox-network"
              ];
              depends_on = [ "nzbdav" ];
              capabilities = {
                SYS_ADMIN = true;
              };
              devices = [
                "/dev/fuse:/dev/fuse:rwm"
              ];
              command = [
                "mount"
                "nzbdav:"
                "/mnt/nzbdav"
                "--uid=1000"
                "--gid=100"
                "--allow-other"
                "--links"
                "--use-cookies"
                "--allow-non-empty"
                "--vfs-cache-mode=full"
                "--vfs-cache-max-size=100G"
                "--vfs-cache-max-age=24h"
                "--buffer-size=0M"
                "--vfs-read-ahead=512M"
                "--dir-cache-time=20s"
              ];
              volumes = [
                "/mnt/nzbdav:/mnt/nzbdav:rshared"
                "/home/magicbox/config/rclone-nzbdav/rclone.conf:/config/rclone/rclone.conf"
              ];
            };
            nzbdav-rclone.out.service = {
              security_opt = [
                "apparmor=unconfined"
              ];
            };
            jellyfin.service = {
              container_name = "jellyfin";
              image = "linuxserver/jellyfin:latest";
              restart = "always";
              environment = {
                PUID = "1000";
                PGID = "100";
                TZ = "America/Indiana/Indianapolis";
                JELLYFIN_PublishedServerUrl = "https://stream.szpunar.cloud";
                NVIDIA_VISIBLE_DEVICES = "all";
              };
              # ports = [
              #   "8096:8096"
              # ];
              networks = [
                "magicbox-network"
              ];
              depends_on = [
                "zurg"
                "rclone"
              ];
              volumes = [
                "/home/magicbox/config/jellyfin:/config"
                "/home/magicbox/data/jellyfin:/cache"
                "/home/magicbox/media:/data"
                "/home/magicbox/manual-media:/data-ro"
                "/mnt/zurg:/media:rshared"
                "/mnt/nzbdav:/mnt/nzbdav:rshared"
              ];
            };
            jellyfin.out.service = {
              deploy = {
                resources = {
                  reservations = {
                    devices = [
                      {
                        driver = "cdi";
                        device_ids = [ "nvidia.com/gpu=all" ];
                        capabilities = [ "gpu" ];
                      }
                    ];
                  };
                };
              };
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
                "/home/magicbox/media:/data"
                "/mnt/nzbdav:/mnt/nzbdav:rshared"
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
                "/home/magicbox/media:/data"
                "/mnt/nzbdav:/mnt/nzbdav:rshared"
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
                "/home/magicbox/media:/data"
                "/mnt/nzbdav:/mnt/nzbdav:rshared"
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
                "/home/magicbox/media:/data"
                "/mnt/nzbdav:/mnt/nzbdav:rshared"
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
                "/home/magicbox/media:/data"
                "/mnt/nzbdav:/mnt/nzbdav:rshared"
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
                "/home/magicbox/media/usenet:/data/usenet:rw"
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
