{
  description = "NAS Nix";

  inputs = {

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; # nixos-unstable

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11"; #release-25.05
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
      # to have it up-to-date or simply don't specify the nixpkgs input
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    home-manager-unstable,
    nix-flatpak,
    determinate,
    nix-cachyos-kernel,
    haumea,
    ...
  }: let
    importedModules = haumea.lib.load {
      src = ./modules;
      loader = haumea.lib.loaders.verbatim;
    };

    importedHardware = haumea.lib.load {
      src = ./hardware;
#      inputs = {
#        inherit inputs;
#        inherit (nixpkgs) lib;
#      };
      loader = haumea.lib.loaders.verbatim;
    };

    importedHosts = haumea.lib.load {
      src = ./hosts;
      inputs = {
        inherit inputs;
        inherit (nixpkgs) lib;
      };
      # This is basically the default loader function from haumea, but
      # if it's a functor with systemType, we pass the correct nixpkgs
      loader = inputs: path: let
        loaded = import path;
        f = nixpkgs.lib.toFunction loaded;
        args = nixpkgs.lib.pipe f [
          nixpkgs.lib.functionArgs
          (builtins.mapAttrs (name: hasDefault:
            if name == "pkgs" && builtins.isAttrs loaded && builtins.hasAttr "systemType" loaded
            then
              import (if loaded.useUnstable or false then nixpkgs-unstable else nixpkgs) {
                system = loaded.systemType;
                config.allowUnfree = true;
                config.nvidia.acceptLicense = true;
                config.permittedInsecurePackages = [
                  "olm-3.2.16"
                ];
              }
            else if name == "pkgs-unstable" && builtins.isAttrs loaded && builtins.hasAttr "systemType" loaded
            then
              import nixpkgs-unstable {
                system = loaded.systemType;
                config.allowUnfree = true;
                config.nvidia.acceptLicense = true;
                config.permittedInsecurePackages = [
                  "olm-3.2.16"
                ];
              }
            else if name == "modulesPath"
            then "${nixpkgs}/nixos/modules"
            else if name == "system"
            then
              if builtins.hasAttr "systemType" loaded
              then loaded.systemType
              else "x86_64-linux" # Default to x86_64-linux if not specified
            else if name == "lib"
            then nixpkgs.lib
            else if name == "nixos-hardware"
            then inputs.nixos-hardware
            else if builtins.hasAttr name inputs
            then inputs.${name}
            else if hasDefault
            then null # Let the function use its default value
            else throw "Required argument '${name}' not found in inputs"))
        ];
        configurationValue = f args;
      in (
        nixpkgs.lib.recursiveUpdate
        configurationValue
        {
          imports = builtins.concatLists [
            # this operator returns whether "imports" is a key within configurationValue
            (
              if (configurationValue ? imports)
              then configurationValue.imports
              else []
            )
            (builtins.attrValues importedModules.nixos)
            (builtins.attrValues importedModules.macos)
          ];
        }
      );
    };

    importedUsers = haumea.lib.load {
      src = ./users;
      loader = haumea.lib.loaders.verbatim;
    };
  in {
    # Allows nix eval for debugging
    inherit importedHosts importedModules importedUsers;

    revision =
      if (self ? shortRev)
      then self.shortRev
      else self.dirtyShortRev;

    formatter = builtins.listToAttrs (map (system: {
      name = system;
      value = nixpkgs.legacyPackages.${system}.alejandra;
    }) ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"]);

    nixosConfigurations =
      builtins.mapAttrs (
        hostname: configuration: let
          system =
            if builtins.hasAttr "systemType" configuration
            then configuration.systemType
            else "x86_64-linux"; # Default to x86_64-linux if not specified
          usersToExclude =
            if builtins.hasAttr "usersToExclude" configuration
            then configuration.usersToExclude
            else []; # Default to empty list if not specified
          nixpkgsToUse = if configuration.useUnstable or false
            then nixpkgs-unstable
            else nixpkgs;
          homeManagerToUse = if configuration.useUnstable or false
            then home-manager-unstable
            else home-manager;
        in
          if builtins.match ".+-linux" system != null
          then
            nixpkgsToUse.lib.nixosSystem {
              inherit system;

              specialArgs = {
                inherit inputs;
                inherit (nixpkgsToUse) lib;
                inherit hostname;
                inherit system;
                modules = importedModules.nixos;
                nixpkgs = nixpkgsToUse;
              };
              modules = [
                determinate.nixosModules.default

                (
                  { pkgs, ... }:
                  {
                    nixpkgs.overlays = [
                      nix-cachyos-kernel.overlays.pinned
                    ];
                  }
                )

                # Load the hardware configuration if it exists from the hardware directory
                (
                  if builtins.hasAttr hostname importedHardware
                  then importedHardware.${hostname}
                  else {}
                )

                (
                  if builtins.pathExists ./default-host-config.nix
                  then ./default-host-config.nix
                  else {}
                )

                (builtins.removeAttrs configuration ["systemType" "usersToExclude" "useUnstable"]) # Remove our own custom attributes but pass configuration

                nix-flatpak.nixosModules.nix-flatpak

                homeManagerToUse.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.backupFileExtension = "backup";

                  home-manager.extraSpecialArgs = {
                    inherit inputs;
                    modules = importedModules.home;
                    pkgs = import nixpkgsToUse {
                      inherit system;
                    };
                  };

                  home-manager.users = let
                    hostUsers =
                      if builtins.hasAttr hostname importedUsers
                      then importedUsers.${hostname}
                      else {};
                    globalUsers = importedUsers.globals;

                    allUsers = builtins.filter (userName: !builtins.elem userName usersToExclude) (nixpkgs.lib.lists.unique (builtins.concatLists [
                      (builtins.attrNames globalUsers)
                      (builtins.attrNames hostUsers)
                    ]));
                  in
                    builtins.listToAttrs (builtins.map (
                        userName: {
                          name = userName;
                          value = args: let
                            base =
                              if builtins.hasAttr userName globalUsers && builtins.hasAttr userName hostUsers
                              then
                                nixpkgs.lib.mkMerge [
                                  (globalUsers.${userName} args)
                                  (hostUsers.${userName} args)
                                ]
                              else if builtins.hasAttr userName globalUsers
                              then globalUsers.${userName} args
                              else hostUsers.${userName} args;
                          in
                            nixpkgs.lib.recursiveUpdate base {
                              imports = builtins.map (module: module args) (builtins.attrValues importedModules.home);
                            };
                        }
                      )
                      allUsers);
                }
              ];
            }
          else null
      )
      (nixpkgs.lib.filterAttrs (k: v: nixpkgs.lib.hasSuffix "linux" v.systemType) importedHosts);

    darwinConfigurations =
      builtins.mapAttrs (
        hostname: configuration: let
          system =
            if builtins.hasAttr "systemType" configuration
            then configuration.systemType
            else "aarch64-darwin"; # Default to aarch64-darwin if not specified
          usersToExclude =
            if builtins.hasAttr "usersToExclude" configuration
            then configuration.usersToExclude
            else []; # Default to empty list if not specified
        in
          if builtins.match ".+-darwin" system != null
          then
            nix-darwin.lib.darwinSystem {
              inherit system;

              specialArgs = {
                inherit inputs;
                inherit (nixpkgs) lib;
                inherit hostname;
                inherit system;
                modules = importedModules.macos;
              };

              modules = [
                (
                  if builtins.pathExists ./default-host-config.nix
                  then ./default-host-config.nix
                  else {}
                )

                (builtins.removeAttrs configuration ["systemType" "usersToExclude"])

                home-manager.darwinModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.backupFileExtension = "backup";

                  home-manager.extraSpecialArgs = {
                    inherit inputs;
                    modules = importedModules.home;
                    pkgs = import nixpkgs {
                      inherit system;
                    };
                  };

                  home-manager.users = let
                    hostUsers =
                      if builtins.hasAttr hostname importedUsers
                      then importedUsers.${hostname}
                      else {};
                    globalUsers = importedUsers.globals;

                    allUsers = builtins.filter (userName: !builtins.elem userName usersToExclude) (nixpkgs.lib.lists.unique (builtins.concatLists [
                      (builtins.attrNames globalUsers)
                      (builtins.attrNames hostUsers)
                    ]));
                  in
                    builtins.listToAttrs (builtins.map (
                        userName: {
                          name = userName;
                          value = args: let
                            base =
                              if builtins.hasAttr userName globalUsers && builtins.hasAttr userName hostUsers
                              then
                                nixpkgs.lib.mkMerge [
                                  (globalUsers.${userName} args)
                                  (hostUsers.${userName} args)
                                ]
                              else if builtins.hasAttr userName globalUsers
                              then globalUsers.${userName} args
                              else hostUsers.${userName} args;
                          in
                            nixpkgs.lib.recursiveUpdate base {
                              imports = builtins.map (module: module args) (builtins.attrValues importedModules.home);
                            };
                        }
                      )
                      allUsers);
                }
              ];
            }
          else null
      )
      (nixpkgs.lib.filterAttrs (k: v: nixpkgs.lib.hasSuffix "darwin" v.systemType) importedHosts);
  };
}
