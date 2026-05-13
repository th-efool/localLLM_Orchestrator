# Remote Access Architecture

## Architecture
- Workstation runs Docker services locally.
- Services exposed on host loopback only.
- Tailscale provides private encrypted remote transport.
- No public ingress, no reverse proxy dependency for remote access, no Kubernetes.

## Recommended host port mappings
- Open WebUI: `127.0.0.1:3000 -> open-webui:8080`
- LiteLLM: `127.0.0.1:4000 -> litellm:4000`
- Ollama (host-native): `127.0.0.1:11434 -> host ollama:11434`

## Docker Compose integration guidance
Update `docker-compose.yml` `ports:` entries to explicit loopback bindings (`127.0.0.1:...`) for any service that should not be LAN/WAN exposed.

## Device access workflows
### Remote laptop -> Open WebUI
1. Connect laptop to tailnet.
2. Start tunnel:
   ```bash
   ssh -L 3000:127.0.0.1:3000 <user>@<workstation>
   ```
3. Open `http://127.0.0.1:3000` in browser.

### Remote laptop -> LiteLLM API
1. Connect to tailnet.
2. Tunnel API port:
   ```bash
   ssh -L 4000:127.0.0.1:4000 <user>@<workstation>
   ```
3. Use `http://127.0.0.1:4000/v1` as OpenAI-compatible base URL.

## Remote IDE workflows
### VS Code SSH
- Use Tailscale hostname in Remote-SSH.
- Run local stack commands (`make up`, `make logs`) on workstation via remote terminal.
- Keep API/web access via tunnels from IDE machine.

### JetBrains Gateway / terminal-only
- Connect over Tailscale SSH.
- Forward needed local ports (`3000`, `4000`) only.

## Endpoint validation helpers
- `./scripts/endpoint_validate.sh` — checks expected local endpoints.
- `./scripts/remote_healthcheck.sh` — host + Docker + HTTP sanity.
- `./scripts/remote_api_verify.sh` — OpenAI-compatible API verification.
