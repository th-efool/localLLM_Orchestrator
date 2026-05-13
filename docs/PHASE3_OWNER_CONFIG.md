# Phase 3 Owner Configuration

## Required owner actions
1. Choose workstation DNS name:
   - Tailscale MagicDNS: `<host>.<tailnet>.ts.net`
   - Or internal DNS pointing to workstation tailnet IP.
2. Get workstation tailnet IP:
   ```bash
   tailscale ip -4
   ```
3. Set `.env`:
   ```bash
   TRAEFIK_HTTP_BIND=127.0.0.1
   TRAEFIK_HTTPS_BIND=<workstation-tailnet-ip>
   DOMAIN_NAME=<workstation-tailnet-dns-name>
   TAILSCALE_DOMAIN=<workstation-tailnet-dns-name>
   WEBUI_AUTH=True
   LITELLM_MASTER_KEY=<new-admin-only-secret>
   LITELLM_SALT_KEY=<new-random-secret>
   ACME_EMAIL=<admin-email>
   ```
4. Configure Tailscale ACLs from `docs/TAILSCALE_SETUP.md`.
5. Configure host firewall:
   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow in on tailscale0 to any port 443 proto tcp
   sudo ufw enable
   ```
6. Start stack:
   ```bash
   docker compose up -d
   ```
7. Create per-user LiteLLM keys.
8. Give users only:
   ```bash
   OPENAI_API_BASE=https://$DOMAIN_NAME/v1
   OPENAI_API_KEY=<their-user-key>
   ```
9. Validate from remote tailnet device:
   ```bash
   ./scripts/remote_healthcheck.sh https://$DOMAIN_NAME
   ./scripts/remote_api_verify.sh https://$DOMAIN_NAME/v1 <user-key> <model>
   ```
10. Verify direct ports fail remotely:
    ```bash
    nc -vz $DOMAIN_NAME 3000
    nc -vz $DOMAIN_NAME 4000
    nc -vz $DOMAIN_NAME 11434
    nc -vz $DOMAIN_NAME 8001
    ```

## Do not do
- Do not expose `3000`, `4000`, `11434`, `8001` to LAN/WAN.
- Do not enable Tailscale Funnel for this stack.
- Do not share `LITELLM_MASTER_KEY` with users.
- Do not commit `.env`.
- Do not disable `WEBUI_AUTH` in team mode.
