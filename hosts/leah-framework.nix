{
  systemType = "aarch64-linux";
  __functor = self: {
    config,
    pkgs,
    ...
  }: let
    session-desktop = name: execCmd:
      pkgs.runCommandNoCC ("session-" + name) {
      } ''
              mkdir -p $out/share/wayland-sessions
              cat > $out/share/wayland-sessions/${name}.desktop <<'EOF'
        [Desktop Entry]
        Name=${name}
        Comment=${name} Wayland session
        Exec=${execCmd}
        Type=Application
        X-GDM-Session-Type=wayland
        EOF
      '';

    niri-session-package = session-desktop "niri" "niri-session";
    cosmic-session-package = session-desktop "cosmic" "cosmic-session";
    kde-wayland-session-package = session-desktop "plasma-wayland" "startplasma-wayland";
  in {
    inherit (self) systemType;

    imports = [
      # Include the results of the hardware scan.
      # ../hardware/saige-macbook-nixos.nix # TODO: use like modules for this or something
    ];

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # networking.hostName = "saige-macbook-nixos"; # Define your hostname. NOW DONE IN flake.nix
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networking.networkmanager.enable = true;

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

    # Enable the X11 windowing system.
    # services.xserver.enable = true;

    # enable the spice guest agent
    services.spice-vdagentd.enable = true;

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
      packages = with pkgs; [
        #  thunderbird
      ];
    };

    # Install firefox.
    programs.firefox.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #  wget
      git
      gh
      vscode-fhs
      ghostty
      alacritty
      pkgs.catppuccin-sddm.override {
        flavor = "mocha";
        accent = "lavender";
        font  = "Noto Sans";
        fontSize = "12";
#        background = "${./wallpaper.png}";
        loginBackground = true;
      }
    ];

    # Enable the COSMIC desktop environment
    services.desktopManager.cosmic.enable = true;
    services.desktopManager.plasma6.enable = true;
    programs.niri.enable = true;
    services.xserver.enable = true;
    services.displayManager.sddm = {
      theme = "catppuccin-mocha-lavender";
      enable = true;
      enableHidpi = true;
      wayland.enable = true;
    };

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
