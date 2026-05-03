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

## Part 1: Fresh Installation (`master` branch)

Install edge with its own services (headscale, coturn, openssh, nginx) and
connect portuus to the new Tailnet. This is the baseline — all services on
portuus are still directly exposed as before.

### 1. Boot into NixOS Rescue

Activate the Hetzner rescue system and mount the [NixOS minimal ISO](https://nixos.org/download/#nixos-iso).

### 2. SSH into the machine

On the Hetzner machine (via console), set a password for the nixos user:

```bash
passwd
```

Then SSH in from your local machine:

```bash
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no nixos@<server-ip>
```

### 3. Run the install script

```bash
sudo -i
```

> The repo is private. Copy the flake directory to `/tmp/nixos` on the host manually, then:
> ```bash
> nix --experimental-features "nix-command flakes" run \
>   git+https://git.sid.ovh/sid/synix#apps.x86_64-linux.install -- \
>   -n edge
> ```

### 4. Set disk ID

Edit `/tmp/nixos/hosts/edge/disks.sh` and set `SSD` to the correct disk ID:

```bash
ls /dev/disk/by-id/
```

### 5. Restore SSH host keys (before reboot!)

sops-nix derives its age key from the SSH host key. To keep the same age identity
(so existing secrets can be decrypted), restore the old host keys before rebooting:

```bash
# From your local machine, copy the backed-up keys onto the new install:
scp ~/edge-ssh-host-key     root@<server-ip>:/mnt/etc/ssh/ssh_host_ed25519_key
scp ~/edge-ssh-host-key.pub root@<server-ip>:/mnt/etc/ssh/ssh_host_ed25519_key.pub

# On the server, fix permissions:
chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
chmod 644 /mnt/etc/ssh/ssh_host_ed25519_key.pub
```

> If you don't have the old keys, sops-nix will generate a new age identity on
> first boot. You then need to add the new age public key to `.sops.yaml` and
> re-encrypt all secrets:
> ```bash
> # Get the new public key (after first boot)
> ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
> # Update .sops.yaml, then re-encrypt
> sops updatekeys hosts/edge/secrets/secrets.yaml
> ```

### 6. Reboot

```bash
umount -Rl /mnt
reboot now
```

### 7. Verify edge is running

```bash
ssh -p 2299 steffen@<server-ip>
```

Headscale, coturn, and openssh should be up.

### 8. Point `hs.portuus.de` to the new edge IP

Update the DNS A record for `hs.portuus.de` to the new edge public IP.
Wait for propagation. All other DNS records stay on portuus for now.

```bash
# Verify DNS is pointing to the new edge
dig +short hs.portuus.de
```

### 9. Disconnect portuus from the old Tailnet

On portuus:

```bash
tailscale down
tailscale logout
```

### 10. Create portuus node on the new Headscale

On edge:

```bash
headscale users create portuus
headscale preauthkeys create --user portuus --reusable --expiration 1h
```

### 11. Connect portuus to the new Headscale

On portuus:

```bash
tailscale up --login-server=https://hs.portuus.de --auth-key=<preauth-key>
```

### 12. Verify Tailnet connectivity

From edge:

```bash
ping 100.64.0.5  # portuus Tailnet IP
```

---

### 13. Deploy `master` to portuus

Portuus is reachable via Tailnet now. Deploy from your local machine:

```bash
deploy .#portuus
```

After this, the GitHub Actions runner is registered against `stherm/portuus` and
all future deploys happen automatically via deploy-rs on push to `master`.

---

**`master` setup is complete.** Edge runs headscale, coturn, openssh. Portuus is
on the Tailnet and still serves all traffic directly. Everything works as before,
just with the new edge. All future changes are deployed automatically.

---

## Part 2: Enable edge proxy (`edge-proxy` branch)

Route all public traffic through edge. After this, portuus no longer needs any
public-facing ports.

### 1. Update all DNS records

Point **all** DNS records to the new edge public IP (see DNS table above).
Wait for propagation.

### 2. Merge `edge-proxy` into `master` and push

```bash
git checkout master
git merge edge-proxy
git push origin master
```

deploy-rs will automatically deploy to both hosts. This enables:
- **edge**: nginx reverse proxy for all HTTP services (with ACME/TLS) + nginx stream for Mail, Minecraft, Rustdesk
- **portuus**: nginx only on Tailnet interface, no public ports, no TLS (terminated on edge)

### 3. Verify all services

```bash
curl -I https://git.portuus.de
curl -I https://cloud.portuus.de
curl -I https://vault.portuus.de
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
