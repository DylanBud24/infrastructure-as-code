{ ... }:

{
  # VS Code itself is installed natively via the OS image (rpm-ostree layer
  # in recipe.yml). User-level config is intentionally NOT symlinked from the
  # flake — VS Code's built-in "Settings Sync" (sign in with GitHub) handles
  # settings, keybindings, snippets, and extensions across machines much more
  # smoothly than a home-manager-managed settings.json (which becomes readonly
  # and breaks in-app save).
  #
  # If you later want full declarative VS Code, replace this module with:
  #
  #   programs.vscode = {
  #     enable = true;
  #     profiles.default = {
  #       userSettings = { ... };
  #       extensions = with pkgs.vscode-extensions; [ ... ];
  #     };
  #   };
}
