# SSH Remote Access Setup

Enable remote SSH access to the home Linux desktop so the user can connect from a laptop (or another machine) and interact with Hermes directly via CLI.

## Use Case

User is at the office (or away from home) and wants to:
- SSH into the home PC from a laptop
- Run `hermes` interactively on the home PC from the remote laptop
- Eventually set up Tailscale/ZeroTier for access from anywhere (not just same LAN)

## Installation

SSH server requires `sudo`:

```bash
sudo apt-get update -qq && sudo apt-get install -y openssh-server
sudo systemctl enable --now ssh
sudo systemctl status ssh
```

**Note:** The user in this environment prefers to run sudo commands themselves. Prepare the command(s) and let them execute it manually from their local terminal (or ask for the sudo password).

## Network Info

```bash
# Get local IP
hostname -I | awk '{print $1}'
# Or
ip route get 1 | head -1
```

## Firewall

If `ufw` is active:

```bash
sudo ufw allow ssh
sudo ufw reload
```

## Connecting

### Same LAN (laptop at home)

```bash
ssh who@192.168.1.X
```

Then run `hermes` to start a CLI session.

### From outside the home network (WAN)

The local IP (e.g. `192.168.1.12`) is NOT reachable from the internet. Options:

1. **Tailscale** — easiest, creates a virtual private network. Install on both machines, then SSH via Tailscale IP.
2. **ZeroTier** — similar to Tailscale, free tier.
3. **Port forwarding** on the home router (not recommended — security risk).
4. **Cloudflare Tunnel / ngrok** — alternative secure tunnels.

**Recommended:** Tailscale. Free for personal use, minimal config.

```bash
# Install on home PC
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Install on laptop (same steps)
# Then both machines appear on the same Tailscale network
ssh who@<tailscale-ip>
```

## Verification

After installation, verify SSH is running:

```bash
systemctl is-active ssh
# Should print: active
```

Test SSH loopback:

```bash
ssh who@127.0.0.1 "echo SSH working"
# Should print: SSH working
```

## Pitfalls

- **Sudo required** — SSH server installation and firewall changes need sudo. Always check with the user before running.
- **User may be away** — if user is at office and needs SSH, they cannot run sudo commands on the home PC remotely unless you (Hermes) do it. Either ask for sudo password or prepare the commands for them to run when they get home.
- **IP changes** — local IP can change after router reboot. Use a static DHCP lease on the router or set a static IP.
- **SSH key auth recommended** — password auth works but keys are more secure (and don't expose the system password).
- **Cloudflare on Upwork** — note that some services (like Upwork) aggressively block bot traffic via Cloudflare, which prevented Hermes from scraping job listings directly. This is NOT an SSH issue but a separate constraint when trying to automate web tasks through Hermes.
