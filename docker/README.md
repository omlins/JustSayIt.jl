# JustSayIt registration environment (Docker image)

A fresh, minimal replica of the GitHub `ubuntu-26.04` runner image that the JustSayIt
registration process (the AutoMerge check in `JuliaRegistries/General`) runs on. Its purpose
is to validate — locally or in CI, without relying on tweaks in the CI workflow — that
`import JustSayIt` installs the Python and non-Julia dependencies correctly with the
package's own build step (`deps/build.jl`).

## What the image contains

- **Ubuntu 26.04 LTS "resolute"** (`ubuntu:26.04`) — the same OS generation as the runner
  image (`20261116.202.1`).
- **Apt essentials**, mirroring the runner image: `ca-certificates` and `curl` (for
  downloads), `git`, `passwd` (provides `useradd`), `sudo`, and `xauth` + `xvfb`
  (providing `xvfb-run`, under which the registration process's import check runs).
- **Julia 1.11.9 and 1.12.7** — the lowest and highest versions compatible with JustSayIt's
  `[compat] julia = "1.11 - 1.12"` — installed via **juliaup**, exactly as the registration
  process's AutoMerge machinery installs them for its import checks: juliaup itself (the
  portable build from the official GitHub release, pinned to `1.24.0`) is extracted to
  `/opt/hostedtoolcache/juliaup` and put on the `PATH`, and the two versions are then
  installed with `juliaup add 1.11.9 1.12.7`, with `juliaup default 1.11.9` making the
  lowest version (where the registration failure occurred) the default channel — the
  versions land in the juliaup depot (`~/.julia/juliaup`), from where the `julia` launcher
  dispatches to the default channel's version; 1.12.7 is available via `julia +1.12.7`.
- **A non-root `runner` user with passwordless sudo**, as on the runner image where jobs
  run as the `runner` user — this is what makes `sudo -n apt-get` work in JustSayIt's
  build step.

## What the image deliberately does NOT contain (the freshness)

- **No Julia package depot** — the Julia depot (`~/.julia`) exists (juliaup puts the
  Julia versions in `~/.julia/juliaup/`), but contains nothing else: no registries, no
  packages, no environments. The simulation uses a fresh temp depot per run, like the
  registration process itself (which checks in fresh temp depots).
- **No conda and no python** — the too-new miniforge environment (conda ≥ 26, python ≥ 3.13)
  is bootstrapped by `Conda.jl` at `Pkg.add` time in the temp depot; the registration
  failure (`InitError: pip_interop is not enabled`) originates there.
- **No X tools** (`xset`, `xrandr`) — they are installed by JustSayIt's own build step at
  `Pkg.add` time (`sudo -n apt-get install x11-utils x11-xserver-utils`).
- **No JustSayIt bits** — no caches, no pre-installed dependencies.

## Build

```bash
docker build --network host -t justsayit-registration-env docker/
```

The `--network host` flag makes the build's `RUN` steps use the host's network
stack — this sidesteps a common Docker quirk where the bridge network's DNS
resolution fails (the base image pull still works, because it goes through the
daemon's own networking, but `apt-get update` inside a `RUN` layer then cannot
resolve `archive.ubuntu.com`). The wrapper `bash docker/build.sh` includes this
flag.

Or via the wrapper: `bash docker/build.sh`. The build downloads the base image
(`ubuntu:26.04`), the juliaup portable build (pinned to `1.24.0`) and the two Julia
versions via juliaup (about 0.5 GB in total); no JustSayIt build/install commands are
executed during the build — they run during the simulation, inside the image, on the
pushed commit.

## Run

```bash
docker run --rm -it justsayit-registration-env bash
```

Or via the wrapper: `bash docker/run.sh [command ...]` (default: `bash`), for example to
verify the environment:

```bash
bash docker/run.sh julia --version                          # 1.11.9 (default channel)
bash docker/run.sh julia +1.12.7 --version                # 1.12.7 (channel selector)
bash docker/run.sh /home/runner/.julia/juliaup/julia-1.11.9+0.x64.linux.gnu/bin/julia --version  # full path
bash docker/run.sh 'xvfb-run -a echo xvfb-run works'     # xvfb-run works
bash docker/run.sh 'sudo -n apt-get --version'            # passwordless sudo works
```

The simulation itself (the one-shot `Pkg.add` + `import JustSayIt` in a single process,
under `xvfb-run`, in a fresh temp depot — mirroring the registration process's import
check) runs inside this image on the pushed commit; it is a separate step and not part
of the image.

> **NOTE** — the shell scripts (`build.sh`, `run.sh`) are committed without the executable
> bit (file creation cannot set it); run them via `bash docker/<script>.sh` or set the bit
> once after cloning: `chmod +x docker/*.sh`.
