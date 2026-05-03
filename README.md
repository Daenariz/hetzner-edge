# portuus

NixOS infrastructure for `portuus.de`. All public traffic enters via **edge** (Hetzner VPS, static IP) and is proxied over the Tailnet to **portuus** (home server).

## Architecture

```
Internet ──► edge (Hetzner, static IP)
               ├─ nginx: TLS termination + reverse proxy (HTTP)
               ├─ nginx stream: TCP/UDP forwarding (Mail, Minecraft, Rustdesk)
               ├─ headscale
               └─ coturn
                    │
                    │ Tailnet (Headscale)
                    │
               portuus (Home Server)
               ├─ GitLab, Nextcloud, Immich, Vaultwarden
               ├─ Matrix Synapse + Maubot
               ├─ Radicale, Jirafeau
               ├─ Mailserver
               ├─ Minecraft Servers
               └─ Rustdesk
```

Only the servers are on the Tailnet. Clients connect through the public edge.

## DNS

All DNS records point to the **edge** static IP:

| Record | Value |
|---|---|
| `portuus.de` | edge IP (Matrix) |
| `git.portuus.de` | edge IP |
| `pages.portuus.de` | edge IP |
| `cloud.portuus.de` | edge IP |
| `gallery.portuus.de` | edge IP |
| `vault.portuus.de` | edge IP |
| `dav.portuus.de` | edge IP |
| `share.portuus.de` | edge IP |
| `hs.portuus.de` | edge IP |
| MX `portuus.de` | edge IP |

## SSH Access

Since no clients are on the Tailnet, use **edge as a jump host**:

```bash
# SSH to edge
ssh -p 2299 user@<edge-public-ip>

# SSH to portuus via edge
ssh -J <edge-public-ip>:2299 -p 2299 user@100.64.0.5
```

Add to `~/.ssh/config` for convenience:

```
Host edge
    HostName <edge-public-ip>
    User steffen
    Port 2299

Host portuus
    HostName 100.64.0.5
    User steffen
    Port 2299
    ProxyJump edge
```

Then simply: `ssh portuus`

## Deploy

Deployments run via GitHub Actions (self-hosted runner on portuus) using [deploy-rs](https://github.com/serokell/deploy-rs).

```bash
# Manual deploy (from a machine on the Tailnet)
deploy .#portuus
deploy .#edge
deploy .              # deploy all
```

## Fresh Installation (Hetzner VPS)

For installing edge on a fresh Hetzner VPS:

### 1. Boot into NixOS Rescue

Activate the Hetzner rescue system and mount the [NixOS minimal ISO](https://nixos.org/download/#nixos-iso), or use [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).

### 2. SSH into the machine

```bash
ssh root@<server-ip>
```

### 3. Run the install script

```bash
sudo -i
nix --experimental-features "nix-command flakes" run \
  git+https://git.sid.ovh/sid/synix#apps.x86_64-linux.install -- \
  -n edge \
  -r https://github.com/stherm/portuus
```

> The repo is private. Copy the flake directory to `/tmp/nixos` on the host manually and omit `-r`:
> ```bash
> nix --experimental-features "nix-command flakes" run \
>   git+https://git.sid.ovh/sid/synix#apps.x86_64-linux.install -- \
>   -n edge
> ```

### 4. Set disk ID

Edit `hosts/edge/disks.sh` and set `SSD` to the correct disk ID:

```bash
ls /dev/disk/by-id/
```

### 5. Reboot

```bash
umount -Rl /mnt
reboot now
```

### 6. Import SOPS keys

Copy the age key to the new machine:

```bash
scp keys.txt root@<server-ip>:/var/lib/sops-nix/keys.txt
```

Then rebuild to decrypt secrets:

```bash
nixos-rebuild switch --flake /path/to/portuus#edge
```

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix). Keys are configured in `.sops.yaml`.

```bash
# Edit secrets
sops hosts/edge/secrets/secrets.yaml
sops hosts/portuus/secrets/secrets.yaml
```

## Constants

All IPs, subdomains, and ports are defined centrally in `constants.nix`.

## Branches

| Branch | Description |
|---|---|
| `master` | Current production (direct traffic to portuus) |
| `edge-proxy` | All traffic routed through edge |

## Useful Commands

```bash
# Evaluate configs (check for errors)
nix eval .#nixosConfigurations.edge.config.system.build.toplevel
nix eval .#nixosConfigurations.portuus.config.system.build.toplevel

# Build locally
nix build .#nixosConfigurations.edge.config.system.build.toplevel
nix build .#nixosConfigurations.portuus.config.system.build.toplevel

# Format all nix files
nix fmt

# Flake check
nix flake check

# Update flake inputs
nix flake update
```
