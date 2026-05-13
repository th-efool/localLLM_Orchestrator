#!/usr/bin/env bash
set -euo pipefail

make up
make health
make verify
