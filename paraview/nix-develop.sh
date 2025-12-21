#!/usr/bin/env bash

set -euo pipefail

nix develop -i \
  --keep DISPLAY \
  --keep WAYLAND_DISPLAY \
  --keep XDG_RUNTIME_DIR
