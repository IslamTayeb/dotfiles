{
  description = "Cross-platform dotfiles with Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system management
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }:
    let
      # Helper function to create home-manager config for different systems
      mkHomeConfig = system: username: extraModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          modules = [
            ./home.nix
            {
              home = {
                inherit username;
                homeDirectory =
                  if system == "x86_64-darwin" || system == "aarch64-darwin"
                  then "/Users/${username}"
                  else "/home/${username}";
                stateVersion = "24.05";
              };
            }
          ] ++ extraModules;

        };
    in
    {
      # macOS configurations
      homeConfigurations = {
        # Your Mac - replace with your actual username
        "islamtayeb@Islams-MacBook-Pro" = mkHomeConfig "aarch64-darwin" "islamtayeb" [ ];

        # Linux server
        "imt11@coltrane" = mkHomeConfig "x86_64-linux" "imt11" [ ];

        # Template for other machines - duplicate and customize as needed
        # "username@linux-server" = mkHomeConfig "x86_64-linux" "username" [];
      };

      # Optional: macOS system configuration with nix-darwin
      darwinConfigurations = {
        macbook = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.islamtayeb = import ./home.nix;
            }
          ];
        };
      };
    };
}
