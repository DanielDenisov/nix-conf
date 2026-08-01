{
  description = "NixOS + Home Manager config — ThinkPad / Catppuccin";

  inputs = {
    nixpkgs.url      = "github:nixos/nixpkgs/nixos-26.05";
    home-manager     = {
      url            = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {

    nixosConfigurations.nixdan = nixpkgs.lib.nixosSystem {
      system  = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };

    homeConfigurations.nixdan = home-manager.lib.homeManagerConfiguration {
      pkgs    = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home.nix ];
    };

  };
}
