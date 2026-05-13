# Tailscale Setup (Secure Remote Access Layer)

## Goal
Add private remote access to this workstation without exposing inference services to the public internet.

## Security model
- Keep all AI services bound to localhost on the host (127.0.0.1).
- Use Tailscale as the only remote-access transport.
- Allow access only from authenticated Tailnet devices.

## 1) Install and join Tailscale
On the workstation:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --accept-routes=false
```

Verify:
```bash
tailscale status
tailscale ip -4
```

## 2) Lock down host firewall
Recommended assumptions:
- Default inbound policy: deny.
- Permit LAN management only if explicitly needed.
- Permit Tailscale interface (`tailscale0`) traffic.
- Do not open 3000/4000/11434/8001 on WAN.

Example (UFW):
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0
sudo ufw enable
sudo ufw status verbose
```

## 3) Compose binding strategy (secure-by-default)
Use loopback-only host port bindings:
```yaml
ports:
  - "127.0.0.1:4000:4000"   # LiteLLM
  - "127.0.0.1:3000:8080"   # Open WebUI
  - "127.0.0.1:11434:11434" # Ollama (if exposed)
  - "127.0.0.1:8001:8000"   # vLLM (optional)
```

This keeps services inaccessible from non-local interfaces.

## 4) Remote access methods
### Option A (preferred): Tailscale SSH + local tunnel
From remote Tailnet device:
```bash
ssh -L 3000:127.0.0.1:3000 -L 4000:127.0.0.1:4000 <user>@<workstation-tailnet-name>
```
Then use local URLs on remote machine:
- Open WebUI: http://127.0.0.1:3000
- LiteLLM API: http://127.0.0.1:4000/v1

### Option B: Tailnet IP direct allowlist (less strict)
If you intentionally allow tailscale0 ingress to bound ports, restrict ACLs in Tailscale admin to selected users/devices only.

## 5) Tailscale ACL recommendation
In Tailscale admin ACLs, allow only trusted identities to workstation tags/hosts and required ports. Keep rules minimal and explicit.

## 6) Validation checklist
On workstation:
```bash
./scripts/remote_healthcheck.sh
```
From remote device (with tunnel):
```bash
./scripts/remote_api_verify.sh http://127.0.0.1:4000/v1 sk-local-change-me
```
