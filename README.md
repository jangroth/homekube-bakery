# homekube-bakery

Builds and publishes the container images that [homekube](https://github.com/jangroth/homekube) runs, so homekube only consumes images and never builds them. Each image is published only after its contract tests pass.

## Images

Public packages on GHCR, `linux/arm64`, with immutable semver tags. [`CONTRACT.md`](CONTRACT.md#consuming-an-image) says how to consume them.

| Image | Reference | Consumer | Status |
|---|---|---|---|
| Coder workspace image | `ghcr.io/jangroth/homekube-bakery/coder-workspace` | Coder template | Published |
| Hermes image | `ghcr.io/jangroth/homekube-bakery/hermes` | herminator | Published |

## Tracked dependencies

The base images and tools each image pins on `main`. Renovate bumps these rows with the Dockerfiles, and CI fails if they drift apart. For what a published tag contains, see [`CONTRACT.md`](CONTRACT.md#consuming-an-image).

### Coder workspace image (`coder-workspace`)

| Dependency | Version |
|---|---|
| `debian` | `13-slim` |
| `anomalyco/opencode` | `2.4.1` |
| `cli/cli` | `2.105.0` |

### Hermes image (`hermes`)

| Dependency | Version |
|---|---|
| `nousresearch/hermes-agent` | `v0.22.2` |
| `debian` | `13-slim` |
| `cli/cli` | `2.105.0` |
| `coder/coder` | `2.39.4` |

## How images are built and published

One workflow, [`images.yml`](.github/workflows/images.yml). Every run tests the release scripts, lints them and checks the README's tracked dependencies against the Dockerfiles, and nothing publishes unless all three pass.

`main` takes no direct pushes: every change is a pull request, rebased onto `main` and merged with a merge commit, and a ruleset with no bypass requires the `ci` check, which passes only when the script tests, lint, the README drift check and every contract test run on the branch pass.

| Trigger | What CI does |
|---|---|
| Push to a branch other than `main` | Builds and runs the contract tests for each image whose directory changed since the branch left `main`. A change to `.github/`, `test/` or `test.sh` builds every image. Publishes nothing. |
| Merge a pull request into `main` | Publishes each image whose directory, `test/` or `test.sh` differs from its last release, or that has no release yet. CI-only changes publish nothing. |
| Manual run (`workflow_dispatch`) | On `main`, publishes every image. On another branch, builds and tests every image. |
| Weekly, Fridays 03:00 UTC | Rebuilds and tests every image, and publishes a patch only where its manifest differs from the last release. |

Dependency bumps reach `main` through [Renovate](renovate.json). It opens a pull request for each bump from a `renovate/*` branch, where CI builds and tests it. GitHub auto-merges the pull request once `ci` passes, which publishes a patch of each image whose Dockerfile changed; GitHub Actions bumps publish nothing. Major bumps, and minor bumps of the upstream Hermes image while it is `v0.x`, wait for approval on the Dependency Dashboard issue.

### The publish pipeline

For each image, CI:

1. builds it and pushes it untagged, by digest
2. runs the contract tests against that digest
3. computes the tag
4. tags the tested digest
5. checks that the tag pulls anonymously
6. creates the git tag `<image>/<version>` and its GitHub Release

Only a digest that passed its contract tests is ever tagged.

Tags follow [ADR 0001](docs/adr/0001-semver-tags-with-computed-patch.md). Each image's `VERSION` holds `MAJOR.MINOR`, and CI picks the patch.

Each release's notes give the tagged reference with its digest and the commit it was built from. Below that come the **Tools** and **Packages** sections, listing what changed in the manifest since the last release, and a **Commits** section listing the commits since then that touched the image, `test/` or `test.sh`. The full manifest is attached as `manifest.txt`. GitHub's "Latest" release is the most recent publish of any image; pin tags and digests rather than relying on it.

Each build runs `apt-get upgrade`, so the weekly run picks up Debian updates, security fixes included. When a weekly run finds the manifest unchanged, it publishes nothing, but the untagged digest it pushed stays in GHCR.

### When CI refuses to publish

A publish run fails rather than publish when:

- on a push to `main`, the checkout is shallow, so release tags may be missing
- GHCR's highest tag for the image disagrees with its last release git tag
- the computed tag is already published, since tags are immutable
- the tag points at a digest other than the tested one
- the tag can't be pulled anonymously

On an image's first publish its GHCR package may start private, so the anonymous pull fails: the operator makes it public in the GHCR web UI (package settings, Change visibility), which can't be undone.

## Where things live

- [Spec #1](https://github.com/jangroth/homekube-bakery/issues/1): what is being built, and why
- [`GLOSSARY.md`](GLOSSARY.md): project vocabulary
- [`docs/adr/`](docs/adr/): architectural decisions
- [`CONTRACT.md`](CONTRACT.md): what each image guarantees its consumers

## Running the contract tests locally

Needs Docker on an arm64 host and [bats](https://github.com/bats-core/bats-core). Builds the image and runs its contract tests:

```sh
./test.sh coder-workspace
```

The release scripts' tests (bats and `python3`), the shellcheck lint and the README drift check need no Docker:

```sh
bats .github/scripts/tests
./lint.sh
.github/scripts/readme-drift.sh README.md images
```

## Changing the contract

Consumers request contract changes as [issues in this repo](https://github.com/jangroth/homekube-bakery/issues).
