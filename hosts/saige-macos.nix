{
  systemType = "aarch64-darwin";
  __functor = self: {
    config,
    pkgs,
    ...
  }: {
    inherit (self) systemType;

    system.configurationRevision = self.rev or self.dirtyRev or null;

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
