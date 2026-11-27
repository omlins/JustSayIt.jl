#!/usr/bin/env bash
# Runs a command (or, by default, an interactive shell) in the JustSayIt
# registration-environment image (see docker/README.md).
# Usage: bash docker/run.sh [command ...]
set -euo pipefail
IMAGE_NAME="justsayit-registration-env"
docker run --rm -it "${IMAGE_NAME}" "${@:-bash}"
