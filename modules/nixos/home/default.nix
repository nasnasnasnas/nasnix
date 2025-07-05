{
  options,
  config,
  lib,
  inputs,
  ...
}: {
  imports = with inputs; [
    home-manager.nixosModules.home-manager
  ];

  config = {
    home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
#      home.file = mkAliasDefinitions options.home.file;
#      xdg.enable = true;
#      xdg.configFile = mkAliasDefinitions options.home.configFile;
#      programs = mkAliasDefinitions options.home.programs;
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPackages = true;

#      users.${config.user.name} =
#        mkAliasDefinitions options.home.extraOptions;
    };
  };
}