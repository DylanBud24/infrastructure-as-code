{ ... }:

{
  programs.git = {
    enable = true;
    # Replace with your real identity before first commit.
    userName = "Dylan";
    userEmail = "dylanbud2424@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rerere.enabled = true;
      merge.conflictstyle = "zdiff3";
      core.editor = "nvim";
      diff.algorithm = "histogram";
    };

    aliases = {
      s = "status -sb";
      co = "checkout";
      ci = "commit";
      lg = "log --oneline --graph --decorate --all";
    };

    ignores = [
      ".DS_Store"
      ".direnv/"
      "result"
      "result-*"
      ".envrc.local"
    ];
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };
}
