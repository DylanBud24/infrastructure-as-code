# Runbook — first-time setup

Step-by-step, assuming this repo is at `~/infrastructure-as-code/` on your current Bazzite machine and you have not yet pushed to GitHub. All `DylanBud24` references have already been substituted.

## Step 1 — generate an image-signing key pair (one-time)

```bash
cd ~/infrastructure-as-code
podman run --rm -it -v "$PWD":/work -w /work gcr.io/projectsigstore/cosign:latest \
    generate-key-pair
# Produces cosign.key (SECRET — never commit!) and cosign.pub (public, commit).
```

Move the public key into place:

```bash
cp cosign.pub image/cosign.pub
cp cosign.pub image/files/system/etc/pki/containers/hypratomic.pub
```

Keep `cosign.key` somewhere safe (1Password, Proton Pass, or encrypted USB). You'll paste its contents into the GitHub repo secret `SIGNING_SECRET` in Step 3.

## Step 2 — create the GitHub repo and push

```bash
gh repo create infrastructure-as-code --public --source=. --remote=origin --push
```

## Step 3 — add the signing secret

```bash
gh secret set SIGNING_SECRET < cosign.key
```

The first build kicks off automatically. Watch it:

```bash
gh run watch
```

## Step 4 — (optional) test the Home Manager flake on the staging VM

From the daily-driver:

```bash
# Copy the flake to the VM
rsync -a --exclude=.git ~/infrastructure-as-code/ dylan@192.168.0.43:~/infrastructure-as-code/

# On the VM, install Nix (manually — sudo asks for password):
ssh dylan@192.168.0.43
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --determinate

# Enable flakes, then eval:
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
cd ~/infrastructure-as-code
nix flake check             # syntax check
nix run home-manager/master -- switch --flake ".#dylan"
```

Expect failures for packages that don't exist on x86_64-linux unfree-by-default — if so, fix `config.allowUnfree` or package name in `modules/packages.nix`.

## Step 5 — rebase the daily-driver

Once the GitHub Action has produced a `:latest` tag:

```bash
bash ~/infrastructure-as-code/bootstrap.sh   # Phase A: stages the rebase
systemctl reboot
```

After reboot you'll land in SDDM → pick Hyprland → log in → open a terminal and:

```bash
bash ~/infrastructure-as-code/bootstrap.sh   # Phase B: Nix + home-manager + login walkthrough
```

## Rollback

If the image is broken:

```bash
rpm-ostree rollback
systemctl reboot
```

Your previous Bazzite deployment is still pinned on disk until you run `rpm-ostree cleanup -p`.
