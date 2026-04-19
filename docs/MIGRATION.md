# Data migration checklist

What to move from the current Bazzite install to the new hypratomic image, and how.
Nothing sensitive goes into the git repo.

## 1. Shell dotfiles → declarative (done in flake)

| Item | Location (Bazzite) | New home |
|---|---|---|
| `.zshrc` aliases, prompt, init | `~/.zshrc` | `modules/shell.nix` (programs.zsh + starship) |
| `.bashrc.d/*` snippets | `~/.bashrc.d/` | Fold into `modules/shell.nix` as needed |
| git config | `~/.gitconfig` | `modules/git.nix` |
| ssh config | `~/.ssh/config` | `modules/shell.nix` (extraConfig) — real host entries go in `~/.ssh/config.d/` (gitignored) |

Before the first `home-manager switch`, review `modules/*.nix` and paste in any aliases or config you actually use.

## 2. Browsers (Brave) → Brave Sync

Brave's profile lives at `~/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/` because it's a Flatpak. **Don't try to rsync this directory** — profile state is tied to machine IDs and will corrupt.

Instead:

1. On Bazzite: `brave://settings/sync` → **Start a new sync chain** → note the 24-word phrase (or QR).
2. Let it sync fully (bookmarks, extensions, history, settings, open tabs).
3. On hypratomic: `flatpak run com.brave.Browser` → `brave://settings/sync` → **I have a chain** → enter phrase.

Passwords are handled separately by Proton Pass — don't let Brave also sync passwords.

## 3. VS Code → Settings Sync

`code --command "workbench.userDataSync.actions.turnOn"` on the old machine signs into GitHub and syncs settings.json, keybindings, snippets, and extensions to Microsoft's cloud. Same command on the new machine pulls them down.

This is simpler and more reliable than symlinking `~/.config/Code/User/settings.json` from the flake (VS Code rewrites it, which breaks read-only symlinks). If you later want full declarativeness, see `modules/vscode.nix` for the `programs.vscode` pattern.

## 4. GPG / SSH keys → manual secure transfer

Never commit these. Never pipe them through a general-purpose sync service.

```bash
# SSH keys (from old machine)
scp -r ~/.ssh dylan@hypratomic-host:~/.ssh-migration
# Then on hypratomic:
mv ~/.ssh-migration/id_ed25519* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# GPG (from old machine)
gpg --export-secret-keys --armor YOUR_KEY_ID > /tmp/gpg-secret.asc
gpg --export-ownertrust > /tmp/gpg-trust.txt
scp /tmp/gpg-secret.asc /tmp/gpg-trust.txt dylan@hypratomic-host:/tmp/
shred -u /tmp/gpg-secret.asc   # on old machine

# On hypratomic
gpg --import /tmp/gpg-secret.asc
gpg --import-ownertrust < /tmp/gpg-trust.txt
shred -u /tmp/gpg-secret.asc /tmp/gpg-trust.txt
```

If you have a YubiKey, prefer re-enrolling over copying private keys.

## 5. Proton Drive → rclone mount

One-time setup (see `modules/rclone-proton-drive.nix` and `~/.config/rclone/BOOTSTRAP.md`):

```bash
rclone config                                            # remote name: protondrive, type: protondrive
systemctl --user enable --now rclone-proton-drive.service
ls ~/ProtonDrive                                         # verify
```

## 6. Application data worth moving

| What | Where on Bazzite | Strategy |
|---|---|---|
| Flatpak app data (Proton apps, Stremio, etc.) | `~/.var/app/<id>/` | Most apps sign in via account; skip raw copy. Exceptions: game saves → back up via the app's own cloud-save. |
| SSH `known_hosts` | `~/.ssh/known_hosts` | Copy over (not secret, but annoying to rebuild). |
| Shell history | `~/.zsh_history` / `~/.bash_history` | Copy if you care — scrub for any secrets first. |
| Custom wallpapers, screenshots | `~/Pictures/` | rsync to `~/ProtonDrive/` → syncs to new machine automatically. |
| Dev projects under `~/Development/` | `~/Development/` | rsync directly to new machine; they're git-managed anyway. |
| Docker/Podman volumes | `~/.local/share/containers/` | Only if you have long-lived volumes. Consider recreating from compose files. |

## 7. What NOT to migrate

- `~/.cache/` — regenerates
- `~/.local/share/flatpak/` — managed by Flatpak
- `~/.mozilla/` (unless you actually use Firefox; Brave is primary)
- `~/.config/BraveSoftware/` (empty on Bazzite — profile is inside `~/.var/app/`)
- `/etc/*` customizations — re-encode them into `image/files/system/etc/` so they're baked into the image

## 8. Pre-rebase safety net

Before running `bootstrap.sh` phase A on the current Bazzite install:

```bash
# Tar important unsynced state to an external drive or Proton Drive.
tar czf ~/pre-rebase-backup-$(date +%F).tar.gz \
    ~/.ssh ~/.gnupg ~/Development ~/Documents ~/.zsh_history \
    --exclude='**/node_modules' --exclude='**/target' --exclude='**/.venv'
```

rpm-ostree rebases are reversible (`rpm-ostree rollback`), but `~/` changes are not.
