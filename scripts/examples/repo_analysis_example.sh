#!/usr/bin/env bash
set -euo pipefail

rg --files | head -n 100
rg "TODO|FIXME|HACK|XXX|deprecated|legacy" || true
