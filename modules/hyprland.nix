{ config, lib, flakeRoot, ... }:

{
  # Hyprland the *compositor* is installed by the BlueBuild image layer
  # (COPR: solopasha/hyprland). This module only manages user-level config.
  xdg.configFile = {
    "hypr/hyprland.conf".source = "${flakeRoot}/hypr/hyprland.conf";
    "waybar/config.jsonc".source = "${flakeRoot}/hypr/waybar.jsonc";
    "waybar/style.css".source = "${flakeRoot}/hypr/waybar.css";
    "kitty/kitty.conf".source = "${flakeRoot}/hypr/kitty.conf";
  };

  # Small convenience: a "start-hyprland" script for TTY login.
  home.file.".local/bin/start-hyprland" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export XDG_SESSION_TYPE=wayland
      export XDG_CURRENT_DESKTOP=Hyprland
      exec Hyprland "$@"
    '';
  };
}
