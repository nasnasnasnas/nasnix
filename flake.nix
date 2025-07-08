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

  outputs = inputs@{ nixpkgs, home-manager, haumea, ... }: 
    let
      pkgsFor = system: import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      
      # Create a function that loads lib with the appropriate pkgs for each system
      libFor = system: haumea.lib.load {
        src = ./.;
        inputs = {
          inherit (nixpkgs) lib;
          pkgs = pkgsFor system;
        };
      };
      
      # Load lib with default system for accessing hosts configuration
      lib = libFor "x86_64-linux";
    in
    {
      inherit lib;

      nixosConfigurations = builtins.mapAttrs (
          hostname: configuration: 
          let
            system = if builtins.hasAttr "systemType" configuration
              then configuration.systemType
              else "x86_64-linux"; # Default to x86_64-linux if not specified
            
            # Load lib with the correct system for this configuration
            systemLib = libFor system;
          in
          nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = { inherit inputs; inherit (nixpkgs) lib; };
            modules = [
              (if builtins.hasAttr hostname systemLib.hardware
                then systemLib.hardware.${ hostname }
                else { }) # Load hardware module if it exists

              { # default module for all hosts TODO: maybe use a file for this
                networking.hostName = hostname;
                nix.settings.experimental-features = [ "nix-command" "flakes" ];
              }

              # Include WSL module for WSL hosts
              (if hostname == "nea-desktop-wsl"
                then inputs.nixos-wsl.nixosModules.default
                else { })

              (builtins.removeAttrs configuration [ "systemType" ]) # Pass configuration but remove our custom attribute

              home-manager.nixosModules.home-manager {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.extraSpecialArgs = {
                  inherit inputs;
                };

                home-manager.users = 
                  let
                  hostUsers = if builtins.hasAttr hostname systemLib.users
                    then systemLib.users.${hostname}
                    else { };
                  globalUsers = systemLib.users.globals;
                  
                  # For WSL systems, only include the nixos user and exclude saige
                  filteredUsers = if hostname == "nea-desktop-wsl"
                    then builtins.removeAttrs (nixpkgs.lib.recursiveUpdate globalUsers hostUsers) [ "saige" ]
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
                  ) filteredUsers;
              }
            ];

            
          }
        ) lib.hosts;
  };
}
