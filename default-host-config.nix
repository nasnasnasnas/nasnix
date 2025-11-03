{
  config,
  pkgs,
  inputs,
  hostname,
  ...
}: {
  networking.hostName = hostname;
  nix.settings.experimental-features = ["nix-command" "flakes"];
}
