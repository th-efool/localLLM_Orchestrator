# Remote Operations Runbook

## Onboard user
1. Add user to tailnet.
2. Require MFA and approved device.
3. Add user to `group:devs` or `group:admins`.
4. Create per-user LiteLLM key.
5. Send user:
   - `OPENAI_API_BASE=https://$DOMAIN_NAME/v1`
   - `OPENAI_API_KEY=<user-key>`
   - Open WebUI URL: `https://$DOMAIN_NAME/`
6. Run remote validation.

## Issue LiteLLM key
Naming:
```text
user:<id>:<purpose>:<YYYY-MM-DD>
```

Rules:
- Do not give users `LITELLM_MASTER_KEY`.
- Scope keys by user/integration where supported.
- Record owner, purpose, issue date, expiry target.
- Rotate quarterly or on incident.

## Revoke user
1. Remove user/device from tailnet or group.
2. Revoke LiteLLM key.
3. Check Traefik access logs.
4. Check LiteLLM auth failures.
5. Confirm remote API call fails.

## Rotate leaked key
1. Create replacement key.
2. Update affected client.
3. Verify new key works.
4. Revoke old key.
5. Audit logs for old key use.

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
- Remove ACLs for `3000`, `4000`, `11434`, `8001`.
- Restart stack.

### Open WebUI unauthenticated
- Set `WEBUI_AUTH=True`.
- Restart `open-webui`.
- Create admin account on first launch.
