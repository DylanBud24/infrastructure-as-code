{
  description = "Dylan's OS-agnostic declarative desktop (Home Manager standalone)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      homeConfigurations.dylan = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
        extraSpecialArgs = { flakeRoot = self; };
      };

      # Convenience alias so `home-manager switch --flake .` works without an explicit target.
      homeConfigurations."dylan@hypratomic" = self.homeConfigurations.dylan;
    };
}
