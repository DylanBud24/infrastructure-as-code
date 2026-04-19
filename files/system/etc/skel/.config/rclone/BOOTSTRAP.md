# Proton Drive via rclone — one-time setup per machine

```bash
rclone config        # create remote named `protondrive`, type `protondrive`
# Enter: Proton email, password, 2FA mailbox password (from account.proton.me → Security → mailbox)
systemctl --user enable --now rclone-proton-drive.service
ls ~/ProtonDrive     # should list Drive contents
```

If the mount fails, check:
```bash
systemctl --user status rclone-proton-drive.service
journalctl --user -u rclone-proton-drive.service -f
```

Never commit `~/.config/rclone/rclone.conf` — it contains encrypted Proton creds.
