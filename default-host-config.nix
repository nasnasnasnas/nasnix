{
  config,
  pkgs,
  inputs,
  hostname,
  ...
}: {
  networking.hostName = hostname;
  nix.settings.experimental-features = ["nix-command" "flakes" "pipe-operators"];

  nixpkgs.config.allowUnfree = true;
}
