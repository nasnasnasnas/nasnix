{
  config,
  pkgs,
  inputs,
  ...
}: {
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";

  modules.starship.enable = true;

  home.file."magicbox/config/caddy".source = "${inputs.self}/common/magicbox-caddy";
  home.file."magicbox/config/caddy".recursive = true;

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
