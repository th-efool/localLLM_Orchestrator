# Remote Access

## Target topology
- Transport: Tailscale only.
- Public internet ingress: none.
- Remote entrypoint: Traefik on `443` via `tailscale0`.
- Web path: remote browser -> Tailscale -> Traefik -> Open WebUI.
- API path: remote client -> Tailscale -> Traefik -> LiteLLM `/v1`.
- Backend services: no direct remote access.
- Local/offline mode: loopback endpoints continue without Tailscale.

## Exposure policy
Allowed remote surface:
- `https://$DOMAIN_NAME/` -> Open WebUI.
- `https://$DOMAIN_NAME/v1/*` -> LiteLLM.
- `https://$DOMAIN_NAME/health/*` -> LiteLLM health.

Blocked remote surface:
- `3000` Open WebUI direct.
- `4000` LiteLLM direct.
- `11434` Ollama direct.
- `8001` vLLM direct.
- Docker backend network.
- Tailscale Funnel unless explicitly approved.

## Modes
### Local/offline mode
Use when single user or no network.

```bash
TRAEFIK_HTTP_BIND=127.0.0.1
TRAEFIK_HTTPS_BIND=127.0.0.1
DOMAIN_NAME=localhost
TAILSCALE_DOMAIN=localhost
```

Endpoints:
- Open WebUI: `http://127.0.0.1:3000` or `https://localhost/`.
- LiteLLM: `http://127.0.0.1:4000/v1` or `https://localhost/v1`.

### Remote team mode
Use when team members need private access.

```bash
TRAEFIK_HTTP_BIND=127.0.0.1
TRAEFIK_HTTPS_BIND=<workstation-tailnet-ip>
DOMAIN_NAME=<workstation-tailnet-dns-name>
TAILSCALE_DOMAIN=<workstation-tailnet-dns-name>
WEBUI_AUTH=True
```

Endpoints:
- Open WebUI: `https://$DOMAIN_NAME/`.
- LiteLLM: `https://$DOMAIN_NAME/v1`.

## Owner setup checklist
1. Create or use existing tailnet.
2. Enable MFA/SSO for all users.
3. Require device approval.
4. Install Tailscale on workstation.
5. Tag workstation as `tag:local-ai-gateway`.
6. Enable Tailscale SSH for admins only.
7. Choose workstation DNS name:
   - Tailscale MagicDNS: `<host>.<tailnet>.ts.net`.
   - Internal DNS pointing to workstation tailnet IP.
8. Set `.env` remote values, including fresh `LITELLM_MASTER_KEY` and `LITELLM_SALT_KEY`.
9. Apply ACLs and host firewall rules.
10. Start stack and validate from remote tailnet device.

## Workstation install
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --accept-routes=false --advertise-tags=tag:local-ai-gateway
tailscale status
tailscale ip -4
```

## Tailscale ACL example
Adjust users/groups to your org.

```json
{
  "groups": {
    "group:admins": ["admin@example.com"],
    "group:devs": ["dev1@example.com", "dev2@example.com"],
    "group:agents": []
  },
  "tagOwners": {
    "tag:local-ai-gateway": ["group:admins"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["group:devs", "group:admins"],
      "dst": ["tag:local-ai-gateway:443"]
    },
    {
      "action": "accept",
      "src": ["group:admins"],
      "dst": ["tag:local-ai-gateway:22"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["group:admins"],
      "dst": ["tag:local-ai-gateway"],
      "users": ["autogroup:nonroot", "root"]
    }
  ]
}
```

Do not add ACLs for `3000`, `4000`, `11434`, or `8001`.

## Host firewall
UFW example:
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 443 proto tcp
sudo ufw deny 3000/tcp
sudo ufw deny 4000/tcp
sudo ufw deny 11434/tcp
sudo ufw deny 8001/tcp
sudo ufw enable
sudo ufw status verbose
```

## DNS/TLS options
Preferred options:
1. Use Tailscale MagicDNS name as `DOMAIN_NAME`.
2. Use internal CA certs if browser trust is needed.
3. Avoid public ACME unless workstation intentionally has public DNS/HTTP reachability.

## Gateway-first rule
- Remote users never connect to app ports directly.
- All remote HTTP traffic enters Traefik first.
- Traefik applies TLS, headers, body-size limits, rate limits, in-flight limits, and access logs.
- LiteLLM remains canonical API gateway for all tools and agents.

## Docker binding policy
- `litellm`: `127.0.0.1:4000:4000` only.
- `open-webui`: `127.0.0.1:3000:8080` only.
- `vllm`: `127.0.0.1:8001:8000` only, optional profile.
- `reverse-proxy`: `TRAEFIK_HTTPS_BIND:443:443`.

## Remote IDE workflows
### VS Code SSH
- Connect to workstation using Tailscale SSH.
- Run repo commands on workstation terminal.
- Use API/web through `https://$DOMAIN_NAME`.

### JetBrains Gateway / terminal-only
- Connect over Tailscale SSH.
- Keep app access through Traefik URL.
- Use SSH tunnels only for emergency local debugging.

## User runbook
### Onboard user
1. Add user to tailnet.
2. Require MFA and approved device.
3. Add user to `group:devs` or `group:admins`.
4. Create per-user LiteLLM key.
5. Send user only:
   - `OPENAI_API_BASE=https://$DOMAIN_NAME/v1`
   - `OPENAI_API_KEY=<user-key>`
   - Open WebUI URL: `https://$DOMAIN_NAME/`
6. Run remote validation.

### Revoke user
1. Remove user/device from tailnet or group.
2. Revoke LiteLLM key.
3. Check Traefik access logs.
4. Check LiteLLM auth failures.
5. Confirm remote API call fails.

### Rotate leaked key
1. Create replacement key.
2. Update affected client.
3. Verify new key works.
4. Revoke old key.
5. Audit logs for old key use.

## Validation
From workstation:
```bash
./scripts/validate_hardening.sh
```

From remote tailnet device:
```bash
./scripts/remote_healthcheck.sh https://$DOMAIN_NAME
./scripts/remote_api_verify.sh https://$DOMAIN_NAME/v1 <user-key> <model>
```

Expected blocked remotely:
```bash
nc -vz $DOMAIN_NAME 3000
nc -vz $DOMAIN_NAME 4000
nc -vz $DOMAIN_NAME 11434
nc -vz $DOMAIN_NAME 8001
```

## Disable remote mode
```bash
TRAEFIK_HTTP_BIND=127.0.0.1
TRAEFIK_HTTPS_BIND=127.0.0.1
DOMAIN_NAME=localhost
TAILSCALE_DOMAIN=localhost
docker compose up -d
```

Optional hard stop:
```bash
sudo tailscale down
```

## Troubleshooting
### DNS fails
```bash
tailscale status
tailscale ip -4
getent hosts $DOMAIN_NAME
```

### HTTPS fails
```bash
docker compose logs reverse-proxy --tail=100
curl -kI https://$DOMAIN_NAME/
```

### API auth fails
```bash
curl -k https://$DOMAIN_NAME/v1/models -H "Authorization: Bearer $OPENAI_API_KEY"
```

### Direct ports reachable remotely
- Check Docker bindings.
- Check UFW rules.
- Remove ACLs for `3000`, `4000`, `11434`, or `8001`.
- Restart stack.

### Open WebUI unauthenticated
- Set `WEBUI_AUTH=True`.
- Restart `open-webui`.
- Create admin account on first launch.

## Do not do
- Do not expose `3000`, `4000`, `11434`, or `8001` to LAN/WAN.
- Do not enable Tailscale Funnel for this stack.
- Do not share `LITELLM_MASTER_KEY` with users.
- Do not commit `.env`.
- Do not disable `WEBUI_AUTH` in team mode.
