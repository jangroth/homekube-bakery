# Contract

What each bakery image guarantees its consumers. Every requirement is enforced by a contract test; an image is published only if all of them pass. Request changes as [issues in this repo](https://github.com/jangroth/homekube-bakery/issues).

## Consuming an image

| Image | Reference | Contract guaranteed from |
|---|---|---|
| Coder workspace image | `ghcr.io/jangroth/homekube-bakery/coder-workspace` | `0.2.0` |
| Hermes image | `ghcr.io/jangroth/homekube-bakery/hermes` | `0.1.0` |

Tags are immutable `MAJOR.MINOR.PATCH` with no `v` and no `latest` ([ADR 0001](docs/adr/0001-semver-tags-with-computed-patch.md)). A major bump breaks the contract, a minor bump adds to it, and a patch keeps it. Each tag has a GitHub Release, tagged `<image>/<version>`, whose notes list the tool, base image and package changes since the previous release, with the full manifest attached as `manifest.txt`.

Pin by tag and digest, and place a `# renovate:` comment above the reference so Renovate keeps it current:

```yaml
# renovate: datasource=docker depName=ghcr.io/jangroth/homekube-bakery/coder-workspace
image: ghcr.io/jangroth/homekube-bakery/coder-workspace:0.2.0@sha256:<digest>
```

Review major bumps by hand: they mean a requirement below changed or went away.

## Coder workspace image

Tests run the image as the Coder template does: as `1000:1000`, with no-new-privileges, all capabilities dropped, and an empty uid-1000-owned tmpfs over `/home/coder`. The exceptions are the default-user and source-label tests, which read the image config (running as `1000:1000` would hide the default user), and the size-budget test, which reads the image's layers.

| Requirement | Contract test |
|---|---|
| The default user is `coder` | [`default user is coder`](images/coder-workspace/tests/contract.bats) |
| The `org.opencontainers.image.source` label points at this repo, so Renovate finds the release notes | [`the source label points at the bakery repo`](images/coder-workspace/tests/contract.bats) |
| uid/gid 1000 is `coder`, with home `/home/coder` | [`uid 1000 is coder with gid 1000 and home /home/coder`](images/coder-workspace/tests/contract.bats) |
| `coder`'s login shell in the user database is bash | [`coder's login shell is bash`](images/coder-workspace/tests/contract.bats) |
| There is no `sudo` | [`there is no sudo`](images/coder-workspace/tests/contract.bats) |
| No setuid or setgid binaries exist | [`no setuid or setgid binaries exist`](images/coder-workspace/tests/contract.bats) |
| Nothing the image needs lives in `/home/coder`; it works with an empty home | [`works with an empty home`](images/coder-workspace/tests/contract.bats) |
| `curl`, `git`, `ssh`, `bash` and `tree` run as uid 1000 | [`curl, git, ssh, bash and tree run as uid 1000`](images/coder-workspace/tests/contract.bats) |
| uid 1000 can create files in `/tmp`, where the Coder agent keeps its binary, logs and socket | [`uid 1000 can create files in /tmp`](images/coder-workspace/tests/contract.bats) |
| `sh`, `curl`, `mktemp`, `chmod`, `head` and `grep` are present for the Coder agent init script | [`the Coder agent init script's commands are present and runnable`](images/coder-workspace/tests/contract.bats) |
| `opencode` is on `PATH` and runs as uid 1000 with an empty home | [`opencode prints its version as uid 1000 with an empty home`](images/coder-workspace/tests/contract.bats) |
| `opencode` and its directory are owned by root | [`opencode and its directory are owned by root`](images/coder-workspace/tests/contract.bats) |
| uid 1000 cannot write to `opencode` or its directory | [`uid 1000 cannot write to opencode or its directory`](images/coder-workspace/tests/contract.bats) |
| OpenCode keeps its config and state under `/home/coder`, so they persist with the Workspace | [`OpenCode creates its config and state under /home/coder on first use`](images/coder-workspace/tests/contract.bats) |
| The uncompressed image is at most 535 MB | [`the uncompressed image is within its 535 MB size budget`](images/coder-workspace/tests/contract.bats) |
| The CA bundle is at `/etc/ssl/certs/ca-certificates.crt` | [`the CA bundle is at /etc/ssl/certs/ca-certificates.crt`](images/coder-workspace/tests/contract.bats) |
| `curl` honours a CA bundle passed through `CURL_CA_BUNDLE` | [`curl trusts a CA bundle passed through CURL_CA_BUNDLE`](images/coder-workspace/tests/ca.bats) |
| The CA-bundle init step (`sh` and `cat` concatenating the system bundle with an extra CA) works under the restricted securityContext | [`the CA-bundle init step runs restricted and keeps the system CAs alongside the extra CA`](images/coder-workspace/tests/ca.bats) |

## Hermes image

Built on the upstream Hermes image. Tests run the image as herminator does. The main container starts as root with `HERMES_UID=1000` and `HERMES_GID=1000` and upstream's entrypoint intact, which remaps the `hermes` user to 1000:1000 before running the command. Init steps replace the entrypoint and run as `1000:1000`, with no-new-privileges and all capabilities dropped. The exceptions are the config and source-label tests, which read the image config, and the size-budget test, which reads the image's layers. A full Hermes boot is not tested: it exercises upstream and needs credentials.

Upstream's `PATH` puts `/opt/data/.local/bin`, on Hermes's data volume, ahead of `/usr/local/bin`, so Hermes can shadow the added tools. The contract guarantees only that it can't modify them.

`gh` and `coder` are upstream release binaries; the build fails unless each matches upstream's published checksum. The Coder CLI is pinned independently of any coderd, so its version can briefly differ from the server it talks to.

| Requirement | Contract test |
|---|---|
| Built on `nousresearch/hermes-agent`, pinned by `vX.Y.Z` tag and digest | [`the upstream Hermes image is pinned by vX.Y.Z tag and digest`](images/hermes/tests/contract.bats) |
| Entrypoint, cmd, user and volumes are upstream's, unchanged | [`entrypoint, cmd, user and volumes are identical to the pinned upstream Hermes image's`](images/hermes/tests/contract.bats) |
| The `org.opencontainers.image.source` label points at this repo, so Renovate finds the release notes | [`the source label points at the bakery repo`](images/hermes/tests/contract.bats) |
| `jq`, `uv` and `uvx` are on `PATH` and run as uid 1000 after the user remap | [`jq, uv and uvx print their versions as uid 1000 after the upstream user remap`](images/hermes/tests/contract.bats) |
| `gh` and the Coder CLI (`coder`) are on `PATH` and run as uid 1000 after the user remap | [`gh and coder print their versions as uid 1000 after the upstream user remap`](images/hermes/tests/contract.bats) |
| uid 1000 cannot write to `jq`, `uv`, `uvx`, `gh`, `coder`, the files they resolve to, or their directories | [`uid 1000 cannot write to jq, uv, uvx, gh or coder, the files they resolve to, or their directories`](images/hermes/tests/contract.bats) |
| The uncompressed bytes added over the pinned upstream image are at most 600 MB | [`the uncompressed bytes added over the pinned upstream Hermes image are within the 600 MB budget`](images/hermes/tests/contract.bats) |
| `sh` and `cat` are present for init steps | [`sh and cat run restricted with the entrypoint replaced`](images/hermes/tests/ca.bats) |
| The CA bundle is at `/etc/ssl/certs/ca-certificates.crt` | [`the CA bundle is at /etc/ssl/certs/ca-certificates.crt`](images/hermes/tests/ca.bats) |
| The CA-bundle init step (`sh` and `cat` concatenating the system bundle with an extra CA) works under the restricted securityContext | [`the CA-bundle init step runs restricted and writes the system CAs followed by the extra CA`](images/hermes/tests/ca.bats) |
