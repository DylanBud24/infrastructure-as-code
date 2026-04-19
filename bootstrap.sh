#!/usr/bin/env bash
#
# Bootstrap for Dylan's declarative desktop.
#
#   curl -fsSL https://raw.githubusercontent.com/DylanBud24/infrastructure-as-code/main/bootstrap.sh | bash
#
# Runs in two phases, detected automatically:
#
#   Phase A (on current OS, before custom image):
#     - Stages an rpm-ostree rebase to ghcr.io/DylanBud24/hypratomic:latest
#     - Asks you to reboot.
#
#   Phase B (after reboot into hypratomic):
#     - Installs Nix via the Determinate Systems installer.
#     - Clones this repo to ~/infrastructure-as-code.
#     - Runs `home-manager switch`.
#     - Walks you through the three one-time logins:
#         1. rclone Proton Drive config
#         2. VS Code Settings Sync (opens a URL)
#         3. Brave Sync chain (opens brave://settings/sync)
#
set -euo pipefail

GH_USER="DylanBud24"
REPO="infrastructure-as-code"
IMAGE="hypratomic"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/${GH_USER}/${IMAGE}:latest"
REPO_URL="https://github.com/${GH_USER}/${REPO}.git"
DOTFILES_DIR="${HOME}/infrastructure-as-code"
MARKER="${HOME}/.local/state/hypratomic-bootstrap.done"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

detect_image() {
    if [[ -x /usr/bin/rpm-ostree ]]; then
        rpm-ostree status --json 2>/dev/null \
            | grep -oE '"container-image-reference"[[:space:]]*:[[:space:]]*"[^"]+"' \
            | head -1 || true
    fi
}

on_hypratomic() {
    detect_image | grep -q "${GH_USER}/${IMAGE}"
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
    say "After reboot, re-run this script to complete setup."
}

phase_b_userland() {
    say "Phase B: user-level setup on ${IMAGE}"

    # 1. Nix via Determinate installer (bootc-aware).
    if ! command -v nix >/dev/null; then
        say "Installing Nix (Determinate Systems, Atomic-aware)."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
            | sh -s -- install ostree --determinate --no-confirm
        # shellcheck disable=SC1091
        . /etc/profile.d/nix.sh || true
    else
        say "Nix already installed; skipping."
    fi

    # 2. Clone dotfiles (or pull latest).
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        say "Cloning ${REPO_URL} → ${DOTFILES_DIR}"
        git clone "$REPO_URL" "$DOTFILES_DIR"
    else
        say "Dotfiles repo already present; pulling."
        git -C "$DOTFILES_DIR" pull --rebase
    fi

    # 3. Enable experimental features (flakes + nix-command) if needed.
    mkdir -p "$HOME/.config/nix"
    if ! grep -q "experimental-features" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
        echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
    fi

    # 4. First-time home-manager install + switch.
    say "Applying home-manager config."
    cd "$DOTFILES_DIR"
    nix run home-manager/master -- switch --flake ".#dylan"

    mkdir -p "$(dirname "$MARKER")"
    touch "$MARKER"

    # 5. Walk through one-time logins.
    say "One-time logins remaining:"
    cat <<EOF

  1. Proton Drive (rclone):
       rclone config     # create remote 'protondrive', type 'protondrive'
       systemctl --user enable --now rclone-proton-drive.service

  2. VS Code Settings Sync:
       code --command "workbench.userDataSync.actions.turnOn"
       (or: Command Palette → "Settings Sync: Turn On")

  3. Brave Sync:
       flatpak run com.brave.Browser brave://settings/sync
       (scan QR code from your other Brave install, or create a new chain)

  4. Proton Pass desktop:
       flatpak run me.proton.Pass     # sign in once; unlocks everything

  5. Tailscale (optional):
       sudo tailscale up

  6. Copy SSH + GPG keys from the old machine (NEVER via git):
       scp -r old-host:~/.ssh ~/.ssh     # then chmod 600 ~/.ssh/id_*
       scp old-host:/tmp/secret.asc /tmp/ && gpg --import /tmp/secret.asc

EOF
    say "Done. Reboot or log out to start Hyprland from SDDM."
}

main() {
    if on_hypratomic; then
        phase_b_userland
    else
        phase_a_rebase
    fi
}

main "$@"
