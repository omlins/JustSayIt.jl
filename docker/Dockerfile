# A fresh, minimal replica of the GitHub ubuntu-26.04 runner image (20261116.202.1) that the
# JustSayIt registration process runs on, for validating that `import JustSayIt` installs its
# Python and non-Julia dependencies correctly with the package's own build step (deps/build.jl),
# without relying on tweaks in the CI workflow.
#
# docker build -t justsayit-registration-env docker/
#
# Essentials only: OS generation (Ubuntu 26.04 LTS "resolute"), apt essentials (ca-certificates,
# curl, git, passwd, sudo, xauth, xvfb), and the two Julia versions (1.11.9 and 1.12.7, the
# lowest and highest compatible with JustSayIt's [compat] julia = "1.11 - 1.12") installed via
# juliaup, exactly as the registration process's AutoMerge machinery installs them for its
# import checks (juliaup channels), with 1.11.9 (where the registration failure occurred) as
# the default channel - the plain `julia` resolves to it; 1.12.7 is available via `julia +1.12.7`.
#
# Deliberately absent (the freshness): the X tools (xset/xrandr), any conda or python
# environment, and any Julia package depot - only the Julia versions themselves are preinstalled
# (via juliaup, in the juliaup depot ~/.julia/juliaup, exactly where the registration
# environment's juliaup-driven setup puts them); everything else is provided by JustSayIt
# itself at Pkg.add time (deps/build.jl), by Conda.jl's miniforge bootstrap in the temp depot,
# or by the simulation (which uses a fresh temp depot per run, like the registration process
# itself).

FROM ubuntu:26.04

# DEBIAN_FRONTEND as an ARG so that it applies to builds only, not to the runtime environment.
ARG DEBIAN_FRONTEND=noninteractive
ARG JULIAUP_VERSION=1.24.0
ARG JULIAUP_TRIPLET=x86_64-unknown-linux-musl

# The apt essentials that the runner image provides (the runner's jobs run as a non-root
# `runner` user with passwordless sudo; xvfb provides xvfb-run, under which the registration
# process's import check runs). passwd provides useradd for the runner user setup below.
# Deliberately NOT installed: x11-utils / x11-xserver-utils (the X tools are installed by
# JustSayIt's build step at Pkg.add time), python3 and anything conda-related.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        passwd \
        sudo \
        xauth \
        xvfb \
    && rm -rf /var/lib/apt/lists/*

# juliaup (the Julia version manager that the registration process's AutoMerge machinery uses
# for its import checks and that the julia-actions GitHub actions use as well), from the
# official GitHub release - being the portable build, the tarball extracts the `juliaup`
# command and the `julia` launcher side by side, and the latter dispatches to the version of
# the default channel.
RUN set -eu; \
    mkdir -p /opt/hostedtoolcache/juliaup; \
    curl -fsSL --retry 3 \
        "https://github.com/JuliaLang/juliaup/releases/download/v${JULIAUP_VERSION}/juliaup-${JULIAUP_VERSION}-${JULIAUP_TRIPLET}-portable.tar.gz" \
        -o /tmp/juliaup.tar.gz; \
    tar -xzf /tmp/juliaup.tar.gz -C /opt/hostedtoolcache/juliaup; \
    rm -f /tmp/juliaup.tar.gz

# Non-root `runner` user with passwordless sudo, as on the runner image where jobs run as the
# `runner` user - this is what makes `sudo -n apt-get` work in JustSayIt's build step.
RUN useradd -m -s /bin/bash runner \
    && echo 'runner ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/runner \
    && chmod 440 /etc/sudoers.d/runner
USER runner
WORKDIR /home/runner

ENV LANG=C.UTF-8
ENV PATH="/opt/hostedtoolcache/juliaup:${PATH}"

# Julia 1.11.9 and 1.12.7, installed via juliaup exactly as the registration process's
# AutoMerge machinery installs them for its import checks, with 1.11.9 (where the registration
# failure occurred) as the default channel - the plain `julia` resolves to it; 1.12.7 is
# available via `julia +1.12.7`. The versions land in the juliaup depot (~/.julia/juliaup),
# from where the `julia` launcher dispatches to the default channel's version.
RUN juliaup add 1.11.9 1.12.7 \
    && juliaup default 1.11.9
