#!/usr/bin/env bash
# Builds the JustSayIt registration-environment image (see docker/README.md).
# Usage: bash docker/build.sh
# The build downloads the base image, the juliaup portable build and the two Julia
# versions via juliaup (about 0.5 GB in total). No JustSayIt build/install commands
# are executed here - they run during the simulation, inside the image, on the
# pushed commit.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="justsayit-registration-env"
docker build --network host -t "${IMAGE_NAME}" "${SCRIPT_DIR}"
