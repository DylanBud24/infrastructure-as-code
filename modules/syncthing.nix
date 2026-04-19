{ ... }:

{
  # Run Syncthing as a user service — no root needed, no system port conflicts.
  services.syncthing = {
    enable = true;
    tray.enable = false;
    # Let Syncthing manage its own config and folder list at ~/.config/syncthing/.
    # Pairing is done via the web UI at http://localhost:8384.
  };
}
