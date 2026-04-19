{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "eza -la --git --icons";
      ls = "eza --icons";
      cat = "bat --paging=never";
      grep = "rg";
      ".." = "cd ..";
      g = "git";
      rebase-image = "rpm-ostree rebase";
    };

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      share = true;
    };

    initExtra = ''
      # direnv + nix-direnv
      eval "$(direnv hook zsh)"

      # zoxide
      eval "$(zoxide init zsh)"

      # fzf keybindings
      if [ -f "${pkgs.fzf}/share/fzf/key-bindings.zsh" ]; then
        source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
      fi

      # Home Manager session vars (on non-NixOS, sourced explicitly)
      [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ] \
        && . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$character";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
    };
  };

  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.ssh = {
    enable = true;
    # Non-sensitive defaults. Real host entries live in ~/.ssh/config.d/ (ignored by flake).
    extraConfig = ''
      AddKeysToAgent yes
      ServerAliveInterval 60
      ServerAliveCountMax 3
      Include ~/.ssh/config.d/*
    '';
  };
}
