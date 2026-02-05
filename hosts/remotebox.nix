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
      #inputs.arion.nixosModules.arion
    ];

    environment.systemPackages = with pkgs; [
      # Add your system packages here
      git
      wget
      curl
      btop
      fastfetch
      hyfetch
      nixd
      ripgrep
      rustc
      bun
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
    nix.settings.trusted-users = [  "magicbox" ];

    programs.nix-ld = {
      enable = true;
      #package = pkgs.nix-ld-rs; # only for NixOS 24.05
    };

    modules.fd.enable = true; # Enable fd file search

    users.users.magicbox = {
      isNormalUser = true;
      description = "magicbox";
      extraGroups = ["networkmanager" "wheel" "docker"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
      ];
    };

    services.openssh.enable = true;
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };

    # Tailscale
    networking.firewall.checkReversePath = "loose";
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };



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

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
