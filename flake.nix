{
  description = "NAS Nix";

  inputs = {
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
    lib = haumea.lib.load {
      src = ./.;
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
            else if builtins.hasAttr name inputs
            then inputs.${name}
            else if hasDefault
            then null # Let the function use its default value
            else throw "Required argument '${name}' not found in inputs"))
          f
        ];
    };
  in {
    inherit lib;

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
              (
                if builtins.hasAttr hostname lib.hardware
                then lib.hardware.${hostname}
                else {}
              ) # Load hardware module if it exists

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
                };

                home-manager.users = let
                  hostUsers =
                    if builtins.hasAttr hostname lib.users
                    then lib.users.${hostname}
                    else {};
                  globalUsers = lib.users.globals;

                  # For WSL systems, only include the nixos user and exclude saige
                  filteredUsers =
                    if hostname == "nea-desktop-wsl"
                    then builtins.removeAttrs (nixpkgs.lib.recursiveUpdate globalUsers hostUsers) ["saige"]
                    else nixpkgs.lib.recursiveUpdate globalUsers hostUsers;
                in
                  builtins.mapAttrs (
                    userName: userConfig:
                    # If user exists in both, merge, else take from whichever set
                      if builtins.hasAttr userName globalUsers && builtins.hasAttr userName hostUsers
                      then nixpkgs.lib.recursiveUpdate globalUsers.${userName} hostUsers.${userName}
                      else if builtins.hasAttr userName globalUsers
                      then globalUsers.${userName}
                      else hostUsers.${userName}
                  )
                  filteredUsers;
              }
            ];
          }
      )
      lib.hosts;
  };
}
