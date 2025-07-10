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
    nixpkgs,
    home-manager,
    haumea,
    ...
  }: let
    # Load lib with default system for accessing hosts configuration
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
      in
        nixpkgs.lib.pipe f [
          nixpkgs.lib.functionArgs
          (builtins.mapAttrs (name: hasDefault:
            if name == "pkgs" && builtins.isAttrs loaded && builtins.hasAttr "systemType" loaded
            then nixpkgs.legacyPackages.${loaded.systemType}
            else if name == "modulesPath"
            then "${nixpkgs}/nixos/modules"
            else if builtins.hasAttr name inputs
            then inputs.${name}
            else if hasDefault
            then null # Let the function use its default value
            else throw "Required argument '${name}' not found in inputs"))
          f
        ];
    };

    importedModules = haumea.lib.load {
      src = ./modules;
      inputs = {
        inherit inputs;
        inherit (nixpkgs) lib;
      };
    };

    importedUsers = haumea.lib.load {
      src = ./users;
      loader = haumea.lib.loaders.verbatim;
    };
  in {
    # Allows nix eval for debugging
    inherit importedHosts importedModules importedUsers;

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
        in
          nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              inherit inputs;
              inherit (nixpkgs) lib;
            };
            modules = [
              # Load the hardware configuration if it exists from /etc/nixos/hardware-configuration.nix
              (
                if builtins.pathExists /etc/nixos/hardware-configuration.nix
                then /etc/nixos/hardware-configuration.nix
                else {}
              )

              {
                # default module for all hosts TODO: maybe use a file for this
                networking.hostName = hostname;
                nix.settings.experimental-features = ["nix-command" "flakes"];
              }

              (builtins.removeAttrs configuration ["systemType"]) # Pass configuration but remove our custom attribute

              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.extraSpecialArgs = {
                  inherit inputs;
                  inherit (nixpkgs) lib;
                  modules = importedModules.home;
                };

                home-manager.users = let
                  hostUsers =
                    if builtins.hasAttr hostname importedUsers
                    then importedUsers.${hostname}
                    else {};
                  globalUsers = importedUsers.globals;

                  # For WSL systems, only include the nixos user and exclude saige
                  #                  filteredUsers =
                  #                    if hostname == "nea-desktop-wsl"
                  #                    then builtins.removeAttrs (nixpkgs.lib.recursiveUpdate globalUsers hostUsers) ["saige"]
                  #                    else nixpkgs.lib.recursiveUpdate globalUsers hostUsers;
                  allUsers = nixpkgs.lib.lists.unique (builtins.concatLists [
                    (builtins.attrNames globalUsers)
                    (builtins.attrNames hostUsers)
                  ]);
                in
                  builtins.map (
                    userName:
                    # If user exists in both, merge, else take from whichever set
                      if builtins.hasAttr userName globalUsers && builtins.hasAttr userName hostUsers
                      then
                        (nixpkgs.lib.recursiveUpdate (globalUsers.${userName} {
                            pkgs = nixpkgs.legacyPackages.${system};
                            modulesPath = "${nixpkgs}/nixos/modules";
                            config = {};
                            inherit inputs;
                            inherit (nixpkgs) lib;
                          })
                          (hostUsers.${userName} {
                            pkgs = nixpkgs.legacyPackages.${system};
                            modulesPath = "${nixpkgs}/nixos/modules";
                            config = {};
                            inherit inputs;
                            inherit (nixpkgs) lib;
                          }))
                      else if builtins.hasAttr userName globalUsers
                      then
                        globalUsers.${userName} {
                          pkgs = nixpkgs.legacyPackages.${system};
                          modulesPath = "${nixpkgs}/nixos/modules";
                          config = {};
                          inherit inputs;
                          inherit (nixpkgs) lib;
                        }
                      else
                        hostUsers.${userName} {
                          pkgs = nixpkgs.legacyPackages.${system};
                          modulesPath = "${nixpkgs}/nixos/modules";
                          config = {};
                          inherit inputs;
                          inherit (nixpkgs) lib;
                        }
                  )
                  allUsers;
              }
            ];
          }
      )
      importedHosts;
  };
}
