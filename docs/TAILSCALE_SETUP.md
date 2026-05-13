# Tailscale Setup

## Owner configuration checklist
1. Create or use existing tailnet.
2. Enable MFA/SSO for all users.
3. Require device approval.
4. Install Tailscale on workstation.
5. Tag workstation as `tag:local-ai-gateway`.
6. Enable Tailscale SSH for admins only.
7. Set `.env` remote values.
8. Apply host firewall rules.
9. Validate remote HTTPS/API access.

## Workstation install
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --accept-routes=false --advertise-tags=tag:local-ai-gateway
tailscale status
tailscale ip -4
```

## Required `.env` values
```bash
TRAEFIK_HTTP_BIND=127.0.0.1
TRAEFIK_HTTPS_BIND=<workstation-tailnet-ip>
DOMAIN_NAME=<workstation-tailnet-dns-name>
TAILSCALE_DOMAIN=<workstation-tailnet-dns-name>
WEBUI_AUTH=True
```

Keep local/offline values when remote access is disabled:
```bash
TRAEFIK_HTTP_BIND=127.0.0.1
TRAEFIK_HTTPS_BIND=127.0.0.1
DOMAIN_NAME=localhost
TAILSCALE_DOMAIN=localhost
```

## ACL example
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
Preferred Phase 3 options:
1. Use Tailscale MagicDNS name as `DOMAIN_NAME`.
2. Use internal CA certs if browser trust is needed.
3. Avoid public ACME unless workstation intentionally has public DNS/HTTP reachability.

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
