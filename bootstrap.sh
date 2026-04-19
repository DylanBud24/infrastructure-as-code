#!/usr/bin/env bash
#
# Bootstrap for Dylan's declarative desktop (image-only model).
#
#   curl -fsSL https://raw.githubusercontent.com/DylanBud24/infrastructure-as-code/main/bootstrap.sh | bash
#
# Runs in two phases, detected automatically:
#
#   Phase A (on the current OS, before the custom image):
#     - Stages an rpm-ostree rebase to ghcr.io/dylanbud24/hypratomic:latest
#     - Asks you to reboot.
#
#   Phase B (after reboot into hypratomic):
#     - Copies /etc/skel/.config/* into ~/.config (without clobbering existing files)
#     - Enables user systemd units (rclone Proton Drive) dormantly
#     - Walks you through one-time logins
#
set -euo pipefail

GH_USER="DylanBud24"
GH_USER_LOWER="dylanbud24"   # GHCR/OCI refs must be lowercase
REPO="infrastructure-as-code"
IMAGE="hypratomic"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/${GH_USER_LOWER}/${IMAGE}:latest"
REPO_URL="https://github.com/${GH_USER}/${REPO}.git"
DOTFILES_DIR="${HOME}/infrastructure-as-code"
MARKER="${HOME}/.local/state/hypratomic-bootstrap.done"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

detect_image() {
    if [[ -x /usr/bin/rpm-ostree ]]; then
        rpm-ostree status --json 2>/dev/null \
            | grep -oE '"container-image-reference"[[:space:]]*:[[:space:]]*"[^"]+"' \
            | head -1 || true
    fi
}

on_hypratomic() {
    detect_image | grep -qi "${GH_USER_LOWER}/${IMAGE}"
}

phase_a_rebase() {
    say "Phase A: rebasing this system to ${IMAGE_REF}"
    command -v rpm-ostree >/dev/null \
        || die "rpm-ostree not found. This script only runs on Fedora Atomic (Silverblue/Kinoite/Bazzite/etc.)."

    say "Current deployment:"
    rpm-ostree status | head -20

    read -rp $'\nProceed with rebase? Type YES to confirm: ' ok
    [[ "$ok" == "YES" ]] || die "Cancelled."

    sudo rpm-ostree rebase "$IMAGE_REF"
    say "Rebase staged. Reboot with: systemctl reboot"
    say "After reboot, log into Hyprland (pick it from the GDM session menu) then re-run this script."
}

sync_skel() {
    # Copy /etc/skel/.* into $HOME without overwriting existing user files.
    # We use `cp -n` semantics so user customizations survive image upgrades.
    say "Syncing /etc/skel → \$HOME (non-destructive, existing files kept)."
    local src="/etc/skel"
    [[ -d "$src" ]] || { warn "/etc/skel missing; skipping."; return; }

    # Walk every hidden file/dir under skel.
    shopt -s dotglob nullglob
    for entry in "$src"/*; do
        local name
        name="$(basename "$entry")"
        # Skip stuff we never want from skel.
        [[ "$name" == "." || "$name" == ".." ]] && continue
        if [[ -d "$entry" ]]; then
            mkdir -p "$HOME/$name"
            # rsync-style: -n = no-clobber
            cp -rn "$entry/." "$HOME/$name/"
        else
            [[ -e "$HOME/$name" ]] || cp "$entry" "$HOME/$name"
        fi
    done
    shopt -u dotglob nullglob
}

enable_user_services() {
    say "Reloading user systemd + enabling dormant services."
    systemctl --user daemon-reload || true
    # rclone-proton-drive has ConditionPathExists on ~/.config/rclone/rclone.conf,
    # so enabling it now is a no-op until you run `rclone config`.
    systemctl --user enable rclone-proton-drive.service 2>/dev/null || true
}

maybe_clone_repo() {
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        say "Cloning ${REPO_URL} → ${DOTFILES_DIR} (for reference + future edits)."
        git clone "$REPO_URL" "$DOTFILES_DIR" 2>/dev/null \
            || warn "Could not clone repo (no git / no network / SSH key missing). Skip; not required."
    fi
}

maybe_set_zsh() {
    if [[ "${SHELL:-}" != "/bin/zsh" && "${SHELL:-}" != "/usr/bin/zsh" ]]; then
        say "Switching default login shell to zsh (sudo password required)."
        sudo chsh -s /bin/zsh "$USER" || warn "chsh failed — you can redo with 'chsh -s /bin/zsh'."
    fi
}

print_manual_steps() {
    cat <<'EOF'

  ──────────────────────────────────────────────────────────────
   One-time logins remaining (do these whenever you're ready):
  ──────────────────────────────────────────────────────────────

  1. Proton Drive (rclone — mounts as ~/ProtonDrive):
       rclone config                    # remote name `protondrive`, type `protondrive`
       systemctl --user restart rclone-proton-drive.service
       ls ~/ProtonDrive

  2. Brave Sync (restore bookmarks / extensions / settings):
       flatpak run com.brave.Browser
       → brave://settings/sync → "I have a sync code"
       → paste your 24-word phrase

  3. VS Code Settings Sync:
       flatpak run com.visualstudio.code
       → F1 → "Settings Sync: Turn On..."
       → sign in with GitHub

  4. Proton Pass (passwords):
       flatpak run me.proton.Pass       # sign in once; unlocks everything

  5. Tailscale (VPN/mesh — optional):
       sudo tailscale up

  6. SSH + GPG keys from old machine (NEVER via git):
       scp old-host:~/.ssh/id_ed25519 ~/.ssh/
       scp old-host:~/.ssh/id_ed25519.pub ~/.ssh/
       chmod 600 ~/.ssh/id_ed25519
       # GPG:
       ssh old-host "gpg --export-secret-keys --armor YOUR_KEY" > /tmp/gpg.asc
       gpg --import /tmp/gpg.asc && shred -u /tmp/gpg.asc

  7. Display config (fix refresh rate, scaling) if needed:
       wdisplays                        # GUI for resolution/refresh/arrangement
       # or by hand: hyprctl monitors   → edit ~/.config/hypr/hyprland.conf

  Refresh the Hyprland config at any time with: Super+Shift+C  (or log out / in).

EOF
}

phase_b_userland() {
    say "Phase B: user-level setup on ${IMAGE}"
    sync_skel
    enable_user_services
    maybe_clone_repo
    maybe_set_zsh

    mkdir -p "$(dirname "$MARKER")"
    touch "$MARKER"

    say "Phase B done."
    print_manual_steps
    say "If you're currently in GNOME, log out and pick Hyprland at the GDM login screen."
}

main() {
    if on_hypratomic; then
        phase_b_userland
    else
        phase_a_rebase
    fi
}

main "$@"
