{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  home.username = "magicbox";
  home.homeDirectory = lib.mkForce "/home/magicbox";

  modules.starship.enable = true;

  home.file."config/caddy".source = "${inputs.self}/common/magicbox-caddy";
  home.file."config/caddy".recursive = true;

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";
}
