# Remote API Access (OpenAI-Compatible)

## Base URL strategy
Preferred remote access path:
- SSH tunnel over Tailnet to workstation localhost
- API Base URL from client: `http://127.0.0.1:4000/v1`

## Auth
- Use LiteLLM master key as Bearer token.
- Rotate keys periodically and store in a local secret manager.

## Example API requests
List models:
```bash
curl -sS -H "Authorization: Bearer $OPENAI_API_KEY" \
  http://127.0.0.1:4000/v1/models
```

Chat completion:
```bash
curl -sS http://127.0.0.1:4000/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen32b","messages":[{"role":"user","content":"Reply with REMOTE_OK"}],"temperature":0}'
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
      "apiBase": "http://127.0.0.1:4000/v1",
      "apiKey": "sk-local-change-me"
    }
  ]
}
```

## Open WebUI remote flow
1. Start tunnel:
```bash
ssh -L 3000:127.0.0.1:3000 <user>@<workstation>
```
2. Browse `http://127.0.0.1:3000`.
3. Open WebUI calls LiteLLM internally (`http://litellm:4000/v1`) via Docker network.

## Security notes
- Do not publish 3000/4000 to public interfaces.
- Do not port-forward on router.
- Keep Tailscale ACLs least-privilege.
