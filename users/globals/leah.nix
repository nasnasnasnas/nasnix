{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "leah";
  home.homeDirectory = "/home/leah";

  programs.zsh.enable = true;

  xdg.configFile."niri/config.kdl".source = ../../common/leah/niri.kdl;

  modules.starship.enable = true;
  programs.starship = {
    settings = lib.mkMerge [
      (builtins.fromTOML
        (builtins.readFile "${pkgs.starship}/share/starship/presets/catppuccin-powerline.toml"
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
