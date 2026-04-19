{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Shell / CLI QoL
    ripgrep
    fd
    bat
    eza
    fzf
    zoxide
    jq
    yq-go
    tree
    btop
    htop
    tmux
    neovim
    unzip
    p7zip

    # Dev
    gh
    git-lfs
    direnv
    nix-direnv
    just

    # Networking / transfer
    rclone
    rsync
    openssh
    wireguard-tools

    # Proton ecosystem (user-level; VPN client is system-level, see recipe.yml)
    proton-pass

    # Hyprland userland helpers (config-level; Hyprland itself comes from the OS image)
    waybar
    rofi-wayland
    wl-clipboard
    grim
    slurp
    swappy
    brightnessctl
    playerctl
    pamixer

    # Fonts (Hyprland + terminal)
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-emoji

    # Terminal
    kitty
  ];

  # Enable Nerd Fonts to be picked up by apps.
  fonts.fontconfig.enable = true;
}
