# Remote API Access (OpenAI-Compatible)

## Base URL strategy
Local/offline:
```bash
OPENAI_API_BASE=http://127.0.0.1:4000/v1
```

Remote Phase 3:
```bash
OPENAI_API_BASE=https://$DOMAIN_NAME/v1
```

Remote traffic must enter through Traefik. Do not connect remote clients directly to `:4000`.

## Auth
- Use per-user/per-integration LiteLLM keys for clients.
- Keep `LITELLM_MASTER_KEY` admin/bootstrap only.
- Never place master key in Continue.dev, agent config, browser clients, or shared docs.
- Key name format: `user:<id>:<purpose>:<YYYY-MM-DD>`.
- Rotate keys quarterly or on incident.

## Example API requests
List models:
```bash
curl -sS -H "Authorization: Bearer $OPENAI_API_KEY" \
  https://$DOMAIN_NAME/v1/models
```

Chat completion:
```bash
curl -sS https://$DOMAIN_NAME/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen32b","messages":[{"role":"user","content":"Reply with REMOTE_OK"}],"temperature":0}'
```

Local fallback:
```bash
curl -sS -H "Authorization: Bearer $OPENAI_API_KEY" \
  http://127.0.0.1:4000/v1/models
```

## Continue.dev remote config example
`config-examples/continue.remote.config.json`:
```json
{
  "models": [
    {
      "title": "Local LiteLLM over Tailscale",
      "provider": "openai",
      "model": "qwen32b",
      "apiBase": "https://<workstation-tailnet-dns-name>/v1",
      "apiKey": "<user-key-not-master-key>"
    }
  ]
}
```

## Open WebUI remote flow
1. Join approved Tailnet device.
2. Browse `https://$DOMAIN_NAME/`.
3. Sign in to Open WebUI.
4. Open WebUI calls LiteLLM internally (`http://litellm:4000/v1`) via Docker network.

## Key revocation runbook
1. Identify key owner and purpose.
2. Create replacement if user remains authorized.
3. Update client config.
4. Revoke old key.
5. Confirm old key fails against `/v1/models`.
6. Check Traefik/LiteLLM logs for continued use.

## Security notes
- Do not publish `3000`, `4000`, `11434`, or `8001` to public interfaces.
- Do not port-forward on router.
- Do not enable Tailscale Funnel without explicit approval.
- Keep Tailscale ACLs least-privilege.
