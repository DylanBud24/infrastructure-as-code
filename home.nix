{ config, pkgs, lib, flakeRoot, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/hyprland.nix
    ./modules/rclone-proton-drive.nix
    ./modules/vscode.nix
    ./modules/syncthing.nix
  ];

  home.username = "dylan";
  home.homeDirectory = "/var/home/dylan";
  home.stateVersion = "25.05";

  # Non-NixOS (Fedora Atomic) integration: XDG vars, session paths, etc.
  targets.genericLinux.enable = true;

  # Make man/info/XDG dirs available to the OS desktop environment.
  xdg.enable = true;

  # Let home-manager manage itself.
  programs.home-manager.enable = true;

  # Nicety: Home Manager news notifications off (too noisy).
  news.display = "silent";
}
