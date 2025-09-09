{
  systemType = "aarch64-darwin";
  __functor = self: {
    config,
    pkgs,
    inputs,
    ...
  }: {
    inherit (self) systemType;

    system.configurationRevision = self.rev or self.dirtyRev or null;

    system.primaryUser = "leah";

    nix-homebrew = {
      enable = true;

      # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
      enableRosetta = true;

      # User owning the Homebrew prefix
      user = "leah";

      # Optional: Declarative tap management
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
      };

      # Optional: Enable fully-declarative tap management
      #
      # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
      mutableTaps = false;
    };

    homebrew.enable = true;
#    homebrew.taps = builtins.attrNames self.nix-homebrew.taps;
    homebrew.casks = [
      { name = "ghostty"; }
    ];

    environment.systemPackages = with pkgs; [
      kitty
      wget
    ];

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 6;

    # The platform the configuration will be used on.
    nixpkgs.hostPlatform = self.systemType;
  };
}
