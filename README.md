# portuus

NixOS infrastructure for `portuus.de`. All public traffic enters via **edge** (Hetzner VPS, static IP) and is proxied over the Tailnet to **portuus** (home server).

## Architecture

```
Internet ──► edge (Hetzner, static IP 178.105.18.167)
               ├─ nginx: TLS termination + reverse proxy (HTTP)
               ├─ nginx stream: TCP/UDP forwarding (Mail, Minecraft, Rustdesk)
               ├─ headscale
               └─ coturn
                    │
                    │ Tailnet (Headscale)
                    │ edge: 100.64.0.1
                    │ portuus: 100.64.0.2
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

All DNS records point to the **edge** static IP (`178.105.18.167`):

| Record | Type | Value |
|---|---|---|
| `portuus.de` | A | 178.105.18.167 |
| `hs.portuus.de` | A | 178.105.18.167 |
| `turn.portuus.de` | A | 178.105.18.167 |
| `cloud.portuus.de` | CNAME | portuus.de |
| `git.portuus.de` | CNAME | portuus.de |
| `pages.portuus.de` | CNAME | portuus.de |
| `gallery.portuus.de` | CNAME | portuus.de |
| `vault.portuus.de` | CNAME | portuus.de |
| `dav.portuus.de` | CNAME | portuus.de |
| `share.portuus.de` | CNAME | portuus.de |
| `mail.portuus.de` | CNAME | portuus.de |
| MX `portuus.de` | MX | portuus.de |

## SSH Access

Since no clients are on the Tailnet, use **edge as a jump host**:

```
Host edge
    HostName 178.105.18.167
    User steffen
    Port 2299

Host portuus
    HostName 100.64.0.2
    User steffen
    Port 2299
    ProxyJump edge
```

Then: `ssh edge` or `ssh portuus`

## Deploy

Deployments run via GitHub Actions (self-hosted runner on portuus) using [deploy-rs](https://github.com/serokell/deploy-rs).

### Manual deploy via scp

Always delete first — `scp` doesn't overwrite existing directories properly.
Always `git commit` before copying — nix builds from the git index.

```bash
# Edge
ssh -p 2299 steffen@178.105.18.167 "rm -rf /tmp/portuus"
scp -r -P 2299 . steffen@178.105.18.167:/tmp/portuus
ssh -p 2299 steffen@178.105.18.167 "nix-shell -p git --run 'sudo nixos-rebuild switch --flake /tmp/portuus#edge'"

# Portuus
ssh -p 2299 steffen@79.248.193.69 "rm -rf /tmp/portuus"
scp -r -P 2299 . steffen@79.248.193.69:/tmp/portuus
ssh -p 2299 steffen@79.248.193.69 "sudo nixos-rebuild switch --flake /tmp/portuus#portuus"
```

## Constants

All IPs, subdomains, and ports are defined centrally in `constants.nix`.

## Secrets

Managed with [sops-nix](https://github.com/Mic92/sops-nix). Keys configured in `.sops.yaml`.

```bash
sops hosts/edge/secrets/secrets.yaml
sops hosts/portuus/secrets/secrets.yaml
```

## Useful Commands

```bash
# Evaluate configs
nix eval .#nixosConfigurations.edge.config.system.build.toplevel
nix eval .#nixosConfigurations.portuus.config.system.build.toplevel

# Format nix files
nix fmt

# Check which nginx config is active
sudo cat /proc/$(pgrep -o nginx)/cmdline | tr '\0' '\n' | grep conf

# Check current system derivation
readlink /run/current-system
```
