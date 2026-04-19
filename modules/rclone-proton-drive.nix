{ config, pkgs, ... }:

let
  mountPoint = "${config.home.homeDirectory}/ProtonDrive";
in
{
  # This module manages the *mount*, not the credentials.
  # One-time bootstrap: run `rclone config` and create a remote named "protondrive"
  # of type "protondrive" (email + password + 2FA mailbox password).
  # The rclone.conf ends up at ~/.config/rclone/rclone.conf — outside git.

  home.file.".config/rclone/BOOTSTRAP.md".text = ''
    # Proton Drive via rclone — bootstrap

    1. Run: `rclone config`
    2. Choose: `n` (new remote)
    3. Name: `protondrive`
    4. Type: `protondrive`
    5. Enter your Proton email, password, and 2FA mailbox password.
    6. Accept defaults for the rest.
    7. Quit and run: `systemctl --user enable --now rclone-proton-drive.service`

    Verify: `ls ~/ProtonDrive` should list your Drive contents.
  '';

  systemd.user.services.rclone-proton-drive = {
    Unit = {
      Description = "Mount Proton Drive via rclone (protondrive backend)";
      Documentation = [ "https://rclone.org/protondrive/" ];
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      # Don't start automatically until the user has run `rclone config`.
      ConditionPathExists = "%h/.config/rclone/rclone.conf";
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount protondrive: ${mountPoint} \
          --vfs-cache-mode full \
          --vfs-cache-max-age 24h \
          --dir-cache-time 72h \
          --poll-interval 15s \
          --umask 077 \
          --log-level INFO
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -u ${mountPoint}";
      Restart = "on-failure";
      RestartSec = "15s";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
