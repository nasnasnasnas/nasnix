{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "leah";
  home.homeDirectory = "/home/leah";

  programs.zsh.enable = true;
  programs.git = {
    enable = true;
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/tUwFHraeGdHJFOpus9CmYKOVNulm6OeZlD5VBJfjF";
      format = "ssh";
      signByDefault = true;
      signer = "/run/current-system/sw/bin/op-ssh-sign";
    };
    settings.user = {
      name = "leah";
      email = "catgirl@catgirlin.space";
    };
  };

  xdg.configFile."niri/config.kdl".source = ../../common/leah/niri.kdl;
  xdg.configFile."waybar" = {
    source = ../../common/leah/waybar/.;
    recursive = true;
  };

  modules.starship.enable = true;
  programs.starship = {
    settings = lib.mkMerge [
      (builtins.fromTOML (
        builtins.readFile "${pkgs.starship}/share/starship/presets/catppuccin-powerline.toml"
      ))
      {
        # here goes my custom configurations
        palette = lib.mkForce "catppuccin_macchiato";
        cmd_duration.show_notifications = lib.mkForce false;
      }
    ];
  };

  # This value determines the Home Manager release that your
  home.packages = [
    pkgs.htop
  ];

  programs.noctalia-shell.enable = true;
  programs.noctalia-shell.settings = {
    settingsVersion = 26;

    general = {
      avatarImage = "/home/leah/pfp.jpg";
      showHibernateOnLockScreen = true;
    };

    ui = {
      fontDefault = "Sans Serif";
      fontFixed = "JetBrainsMono Nerd Font";
    };

    location = {
      name = "Indianapolis, IN";
      useFahrenheit = true;
      use12hourFormat = true;
      showWeekNumberInCalendar = true;
    };

    calendar = {
      cards = [
        { enabled = true; id = "calendar-header-card"; }
        { enabled = true; id = "calendar-month-card"; }
        { enabled = true; id = "timer-card"; }
        { enabled = true; id = "weather-card"; }
      ];
    };

    screenRecorder = {
      directory = "/home/leah/Videos";
    };

    wallpaper = {
      enabled = true;
      overviewEnabled = true;
      directory = "/home/leah/Pictures/Wallpapers";
      fillColor = "#b89cff";
    };

    appLauncher = {
      enableClipboardHistory = true;
      terminalCommand = "ghostty --";
    };

    controlCenter = {
      cards = [
        { enabled = true; id = "profile-card"; }
        { enabled = true; id = "shortcuts-card"; }
        { enabled = true; id = "audio-card"; }
        { enabled = true; id = "weather-card"; }
        { enabled = true; id = "media-sysmon-card"; }
      ];
    };

    systemMonitor = {
      networkPollingInterval = 1500;
    };

    dock = {
      enabled = true;
      displayMode = "auto_hide";
      floatingRatio = 1.5;
      size = 1.35;
      onlySameOutput = true;
      monitors = [ "eDP-1" ];
      pinnedApps = [ "com.mitchellh.ghostty" ];
    };

    osd = {
      autoHideMs = 2500;
      backgroundOpacity = 0.5;
      location = "bottom";
      enabledTypes = [ 0 1 2 3 ];
    };

    colorSchemes = {
      predefinedScheme = "Tokyo Night";
      darkMode = false;
      schedulingMode = "location";
      matugenSchemeType = "scheme-content";
      generateTemplatesForPredefined = true;
    };

    bar = {
      backgroundOpacity = 0;
      density = "comfortable";
      outerCorners = false;
      widgets = {
        left = [
          {
            icon = "rocket";
            id = "CustomButton";
            leftClickExec = "noctalia-shell ipc call launcher toggle";
          }
          {
            colorizeIcons = false;
            hideUnoccupied = true;
            id = "TaskbarGrouped";
            labelMode = "index";
            showLabelsOnlyWhenOccupied = false;
          }
          {
            diskPath = "/";
            id = "SystemMonitor";
            showCpuTemp = true;
            showCpuUsage = true;
            showDiskUsage = true;
            showMemoryAsPercent = false;
            showMemoryUsage = true;
            showNetworkStats = true;
            usePrimaryColor = true;
          }
          {
            colorizeIcons = false;
            hideMode = "hidden";
            id = "ActiveWindow";
            maxWidth = 250;
            scrollingMode = "hover";
            showIcon = true;
            useFixedWidth = false;
          }
          {
            hideMode = "hidden";
            hideWhenIdle = false;
            id = "MediaMini";
            maxWidth = 200;
            scrollingMode = "hover";
            showAlbumArt = true;
            showArtistFirst = true;
            showProgressRing = true;
            showVisualizer = true;
            useFixedWidth = false;
            visualizerType = "linear";
          }
        ];
        right = [
          { id = "ScreenRecorder"; }
          {
            blacklist = [ ];
            colorizeIcons = false;
            drawerEnabled = false;
            id = "Tray";
            pinned = [ ];
          }
          {
            hideWhenZero = true;
            id = "NotificationHistory";
            showUnreadBadge = true;
          }
          {
            deviceNativePath = "";
            displayMode = "alwaysShow";
            id = "Battery";
            warningThreshold = 30;
          }
          { id = "PowerProfile"; }
          {
            displayMode = "alwaysShow";
            id = "Volume";
          }
          {
            displayMode = "alwaysShow";
            id = "Brightness";
          }
          {
            formatHorizontal = "h:mm:ss AP\nddd, MMM dd";
            formatVertical = "HH mm - dd MM";
            id = "Clock";
            useCustomFont = false;
            usePrimaryColor = false;
          }
          {
            colorizeDistroLogo = false;
            colorizeSystemIcon = "none";
            customIconPath = "";
            enableColorization = false;
            icon = "noctalia";
            id = "ControlCenter";
            useDistroLogo = true;
          }
        ];
        center = [ ];
      };
    };

    nightLight = {
      enabled = true;
      autoSchedule = true;
      nightTemp = "4525";
    };
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";
}
