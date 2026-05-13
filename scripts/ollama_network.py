#!/usr/bin/env python3
import argparse
import json
import os
import socket
import struct
import sys
import time
import urllib.error
import urllib.request
from urllib.parse import urlparse, urlunparse

BASE = os.getenv("OLLAMA_API_BASE", "http://host.docker.internal:11434").rstrip("/")
EXTRA = os.getenv("OLLAMA_FALLBACK_HOSTS", "").strip()
RETRIES = int(os.getenv("OLLAMA_CONNECT_RETRIES", "6"))
SLEEP = float(os.getenv("OLLAMA_CONNECT_SLEEP", "2"))
TIMEOUT = float(os.getenv("OLLAMA_CONNECT_TIMEOUT", "5"))


def log(msg):
    print(f"[ollama-net] {msg}", file=sys.stderr)


def default_gateway():
    try:
        with open("/proc/net/route", "r", encoding="utf-8") as f:
            for line in f.readlines()[1:]:
                fields = line.split()
                if len(fields) >= 3 and fields[1] == "00000000":
                    return socket.inet_ntoa(struct.pack("<L", int(fields[2], 16)))
    except OSError:
        return ""
    return ""


def resolve(host):
    try:
        return sorted({x[4][0] for x in socket.getaddrinfo(host, None)})
    except socket.gaierror:
        return []


def with_host(base, host):
    u = urlparse(base)
    port = u.port or (443 if u.scheme == "https" else 80)
    netloc = f"{host}:{port}"
    return urlunparse((u.scheme or "http", netloc, u.path.rstrip("/"), "", "", "")).rstrip("/")


def candidates(base=BASE):
    out = []
    def add(url):
        if url and url not in out:
            out.append(url.rstrip("/"))
    add(base)
    u = urlparse(base)
    for host in [x.strip() for x in EXTRA.split(",") if x.strip()]:
        add(with_host(base, host))
    gw = default_gateway()
    if gw:
        add(with_host(base, gw))
    add(with_host(base, "172.17.0.1"))
    return out


def fetch_tags(url):
    req = urllib.request.Request(f"{url.rstrip('/')}/api/tags")
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return json.loads(r.read().decode())


def discover(required=True, retries=RETRIES):
    host = urlparse(BASE).hostname or ""
    log(f"configured OLLAMA_API_BASE={BASE}")
    log(f"host.docker.internal addresses={','.join(resolve('host.docker.internal')) or '<unresolved>'}")
    log(f"configured host {host} addresses={','.join(resolve(host)) or '<unresolved>'}")
    log(f"default gateway={default_gateway() or '<unknown>'}")
    last = None
    for i in range(1, retries + 1):
        for url in candidates(BASE):
            try:
                payload = fetch_tags(url)
                names = [m.get("name") for m in payload.get("models", []) if m.get("name")]
                log(f"reachable {url}/api/tags models={len(names)}")
                return url, payload
            except (OSError, urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
                last = e
                log(f"attempt {i}/{retries} failed {url}/api/tags: {e}")
        if i < retries:
            time.sleep(SLEEP)
    msg = (
        "Ollama unreachable from container. Tested: "
        + ", ".join(f"{u}/api/tags" for u in candidates(BASE))
        + ". Remediation: keep Ollama running on the WSL host, set OLLAMA_HOST=0.0.0.0:11434 before starting Ollama, "
        + "ensure Windows/WSL firewall allows Docker bridge traffic, or set OLLAMA_FALLBACK_HOSTS to the reachable WSL/Docker gateway IP. "
        + f"Last error: {last}"
    )
    if required:
        raise SystemExit(msg)
    log(msg)
    return BASE, {"models": []}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    url, payload = discover(required=True)
    if args.json:
        print(json.dumps({"api_base": url, "models": payload.get("models", [])}, indent=2))
    else:
        names = [m.get("name") for m in payload.get("models", []) if m.get("name")]
        print(f"OLLAMA_EFFECTIVE_API_BASE={url}")
        print(f"OLLAMA_MODELS={','.join(names)}")


if __name__ == "__main__":
    main()
