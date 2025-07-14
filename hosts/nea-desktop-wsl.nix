{
  systemType = "x86_64-linux"; # This is used for the value of "system" in the flake.nix file.
  __functor = self: {
    config,
    pkgs,
    inputs,
    ...
  }: {
    inherit (self) systemType;

    usersToExclude = ["saige"]; # Exclude these users from users/globals

    imports = [
      inputs.nixos-wsl.nixosModules.default
    ];

    wsl.enable = true;
    wsl.defaultUser = "nixos";

    environment.systemPackages = with pkgs; [
      # Add your system packages here
      git
      wget
      curl
      btop
      fastfetch
    ];

    programs.nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs; # only for NixOS 24.05
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
