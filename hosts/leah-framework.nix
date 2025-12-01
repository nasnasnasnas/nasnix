{
  systemType = "x86_64-linux";
  useUnstable = true;
  __functor = self: {
    config,
    pkgs,
    pkgs-unstable,
    inputs,
    modulesPath,
    lib,
    ...
  }: {
    inherit (self) systemType;

    imports = [
      # Include the results of the hardware scan.
      # ../hardware/saige-macbook-nixos.nix # TODO: use like modules for this or something
      (modulesPath + "/installer/scan/not-detected.nix")
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ];

    services.fwupd.enable = true;

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.initrd.kernelModules = [ "amdgpu" ];

    boot.kernelPackages = pkgs.linuxPackages_latest;

    boot.initrd.luks.devices."luks-4605a5aa-60f0-4ba3-8ed1-7925f881670d".device = "/dev/disk/by-uuid/4605a5aa-60f0-4ba3-8ed1-7925f881670d";

#    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # networking.hostName = "saige-macbook-nixos"; # Define your hostname. NOW DONE IN flake.nix
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networking.networkmanager.enable = true;
    networking.networkmanager.wifi.backend = "iwd";
    networking.networkmanager.wifi.powersave = false;

    # Set your time zone.
    time.timeZone = "America/Indiana/Indianapolis";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    services.fprintd.enable = true;

    # Enable the X11 windowing system.
    # services.xserver.enable = true;
#     services.xserver.enable = true;
    services.xserver.videoDrivers = [ "amdgpu" ];

    # Enable the GNOME Desktop Environment.
    # services.xserver.displayManager.gdm.enable = true;
    # services.xserver.desktopManager.gnome.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    users.users.leah = {
      isNormalUser = true;
      description = "Leah Szpunar";
      extraGroups = ["networkmanager" "wheel"];
      shell = pkgs.zsh;
      packages = with pkgs; [
        #  thunderbird
      ];
    };

    users.users.nea = {
      isNormalUser = true;
      description = "Nea Szpunar";
      extraGroups = ["networkmanager" "wheel"];
    };

    # Install firefox.
    programs.firefox.enable = true;
    programs._1password.enable = true;
    programs._1password-gui.enable = true;
    programs._1password-gui.polkitPolicyOwners = [ "leah" ];
    programs.steam.enable = true;
    programs.kdeconnect.enable = true;

    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          zen-beta
          zen
        '';
        mode = "0755";
      };
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #  wget
      git
      gh
      bun
      pkgs-unstable.nodejs_24
      vscode-fhs
      ghostty
      alacritty
      jetbrains-toolbox
      vesktop
      pkgs-unstable.element-desktop
#      pkgs-unstable.nheko
      # pkgs-unstable.fluffychat
      microsoft-edge
      neofetch
      fastfetch
      prismlauncher
      lunar-client
      powertop
      rustup
      epiphany
      seahorse
      (catppuccin-sddm.override {
        flavor = "mocha";
#        accent = "lavender";
        font = "Noto Sans";
        fontSize = "13";
        #        background = "${./wallpaper.png}";
        loginBackground = true;
      })

      inputs.zen-browser.packages."${system}".default
      pkgs-unstable.floorp-bin
      pkgs-unstable.ollama
      pkgs-unstable.kdePackages.kamoso
      cheese
      wl-clipboard
      libreoffice-fresh
      rustup
      clang
      github-desktop
      gh
      fuzzel
      waybar
      nerd-fonts.jetbrains-mono
      nil
      powershell
      xwayland-satellite
      swaylock
      swayidle
      mako
      xeyes
      gimp3
      android-studio
      brightnessctl

      # kde stuff
      kdePackages.ark
      kdePackages.gwenview
      kdePackages.okular
      kdePackages.kate
      kdePackages.ktexteditor
      kdePackages.dolphin
      kdePackages.dolphin-plugins

      protonup-qt
      libnotify
    ];

    programs.zsh.enable = true;

    # Enable the COSMIC desktop environment
    services.desktopManager.cosmic.enable = true;
    services.desktopManager.plasma6.enable = false;
    programs.niri.enable = true;
    services.xserver.enable = true;
    services.xserver.xkb.options = "terminate:";
    services.displayManager.sddm = {
      theme = "breeze"; #-lavender";
      enable = false;
      enableHidpi = true;
      wayland.enable = true;
    };
    services.displayManager.cosmic-greeter.enable = true;

    services.tailscale.enable = true;
    services.tailscale.package = pkgs-unstable.tailscale;
    networking.nameservers = [ "100.100.100.100" "1.1.1.1" ];
    networking.search = [ "rockhopper-butterfly.ts.net" ];

    system.autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "--print-build-logs"
      ];
      dates = "04:00";
      randomizedDelaySec = "45min";
      allowReboot = true;
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 45d";
    };

    nix.optimise.automatic = true;
    nix.optimise.dates = [ "03:30" ];

    modules.wifiman.enable = true;

    # use gnome keyring
    security.pam.services = {
#       login.kwallet.enable = lib.mkForce false;
#       kde.kwallet.enable = lib.mkForce false;
    };
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.swaylock = {};
#    programs.seahorse.enable = true;

   services.tlp.enable = false;
   services.tuned = {
     enable = true;
     ppdSupport = true;
   };

    services.cpupower-gui.enable = true;

    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };

    services.geoclue2 = {
      submitData = true;
      submissionNick = "puppyleah";
    };


    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    services.flatpak.enable = true;
    services.flatpak.packages = [
      "org.vinegarhq.Sober"
      "org.vinegarhq.Vinegar"
    ];

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    # List services that you want to enable:

    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
