{ config, pkgs, ... }:

{
  # Replace with your actual username and home path
  home.username = "nixdan";
  home.homeDirectory = "/home/nixdan";

  nixpkgs.config.allowUnfree = true;

  # State version helps Home Manager know which default settings to apply. 
  # Leave this at the version you originally installed.
  home.stateVersion = "26.05"; 

  # Install your user-specific packages here (No sudo needed)
  home.packages = with pkgs; [
    git
    fastfetch
    st
    firefox 
    kitty
    claude-code
  ];

  
  programs.git = {
    enable = true;
    settings.user = {
      name = "Daniel";
      email = "github@danieldenisov.com";
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
