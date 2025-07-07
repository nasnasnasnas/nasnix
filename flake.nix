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
  };

  outputs = inputs@{ nixpkgs, home-manager, haumea, ... }: {
    lib = haumea.lib.load {
      src = ./.;
      inputs = {
        inherit (nixpkgs) lib;
        inherit (home-manager) lib;
        inherit (haumea) lib;
      };
    };

    nixosConfigurations = {
      # TODO please change the hostname to your own
      saige-macbook-nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";

        specialArgs = { inherit inputs; nixosModules = [ ./modules/nixos ]; };
        modules = [
          ./hosts/saige-macbook-nixos.nix

          # make home-manager as a module of nixos
          # so that home-manager configuration will be deployed automatically when executing `nixos-rebuild switch`
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # TODO also import saige@saige-macbook-nixos if it exists
            home-manager.users.saige = import ./users/saige.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix
          }
        ];
      };
    };
  };
}
