{
  description = "NAS Nix";

  inputs = {
    # todo: try unstable?
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    haumea,
    ...
  }: let
    importedModules = haumea.lib.load {
      src = ./modules;
      inputs = {
        inherit inputs;
        inherit (nixpkgs) lib;
      };
      loader = haumea.lib.loaders.verbatim;
    };

    importedHardware = haumea.lib.load {
      src = ./hardware;
      inputs = {
        inherit inputs;
        inherit (nixpkgs) lib;
      };
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
            then import nixpkgs { system = loaded.systemType; config.allowUnfree = true; }
            else if name == "modulesPath"
            then "${nixpkgs}/nixos/modules"
            else if name == "system"
            then
              if builtins.hasAttr "systemType" loaded
              then loaded.systemType
              else "x86_64-linux" # Default to x86_64-linux if not specified
            else if name == "lib"
            then nixpkgs.lib
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

    revision = if (self ? shortRev) then self.shortRev else self.dirtyShortRev;

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
        in
          nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              inherit inputs;
              inherit (nixpkgs) lib;
              inherit hostname;
              inherit system;
              modules = importedModules.nixos;
            };
            modules = [
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

              (builtins.removeAttrs configuration ["systemType" "usersToExclude"]) # Remove our own custom attributes but pass configuration

              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

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
      )
      importedHosts;
  };
}
